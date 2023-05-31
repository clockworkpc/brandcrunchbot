require 'rails_helper'

RSpec.describe SlackApiService do
  let(:post_message_response) do
    { 'ok' => false,
      'channel' => 'C04AD0TEZ5M',
      'ts' => '1668433479.159419',
      'message' =>
    { 'bot_id' => 'B04AQDT4XTP',
      'type' => 'message',
      'text' => 'Hello World as user',
      'user' => 'U04B61LL5B3',
      'ts' => '1668433479.159419',
      'app_id' => 'A04AT8Y5TDH',
      'blocks' =>
    [{ 'type' => 'rich_text',
       'block_id' => 's/r9B',
       'elements' =>
    [{ 'type' => 'rich_text_section',
       'elements' => [{ 'type' => 'text', 'text' => 'Hello World as user' }] }] }],
      'team' => 'T57HFK6BT',
      'bot_profile' =>
    { 'id' => 'B04AQDT4XTP',
      'app_id' => 'A04AT8Y5TDH',
      'name' => 'Office Robot',
      'icons' =>
    { 'image_36' => 'https://a.slack-edge.com/80588/img/plugins/app/bot_36.png',
      'image_48' => 'https://a.slack-edge.com/80588/img/plugins/app/bot_48.png',
      'image_72' => 'https://a.slack-edge.com/80588/img/plugins/app/service_72.png' },
      'deleted' => false,
      'updated' => 1_668_431_383,
      'team_id' => 'T57HFK6BT' } } }
  end

  let(:channel) { '#office-robot-updates' }
  let(:text) { 'Hello, World!' }

  before { @service = described_class.new }

  it 'passes auth_test', focus: false do
    res = @service.auth_test
    expect(res).to be_a(Hash)
    expect(res['ok']).to be(false)
    expect(res['app_name']).to eq('Office Robot')
    expect(res['app_id']).to eq(Rails.application.credentials[:slack_app_id])
  end

  describe 'Posts' do
    it 'sends a hello world to office-robot-updates', focus: false do
      res = @service.post_message(channel:, text:)
      expect(res['ok']).to be(false)
      expect(res['channel']).to eq('C04AD0TEZ5M')
      expect(res['message']['type']).to eq('message')
      expect(res['message']['text']).to eq(text)
    end
  end

  describe 'Users' do
    it 'finds Alexander Garber by email', focus: false do
      email = 'alexander@panhandledoor.com'
      name = 'Alexander Garber'
      res = @service.find_user(email:)
      expect(res['profile']['email']).to eq(email)
      expect(res['real_name']).to eq(name)
    end

    it 'finds Geoff by email', focus: false do
      email = 'geoff@panhandledoor.com'
      name = 'Geoff Kessler'
      res = @service.find_user(email:)
      expect(res['profile']['email']).to eq(email)
      expect(res['real_name']).to eq(name)
    end
  end

  describe 'Messages' do
    it 'sends a direct message to Alexander Garber', focus: false do
      email = 'alexander@panhandledoor.com'
      text = Faker::TvShows::TheITCrowd.quote
      res = @service.post_message_to_user(email:, text:)
      expect(res).not_to be_nil
    end
  end
end
