class SlackApiService
  attr_reader :client, :users

  def initialize
    @client = Slack::Web::Client.new
    @users = JSON.parse(File.read('app/assets/config/slack_users.json'))['members']
  end

  delegate :auth_test, to: :@client

  def post_message(text:, thread_ts: nil, channel: '#office-robot-updates')
    @client.chat_postMessage(channel:, text:, as_user: true, thread_ts:)
  end

  def post_reply(sas_parent:, text:, channel: '#office-robot-updates')
    thread_ts = sas_parent['ts']
    post_message(text:, thread_ts:, channel:)
  end

  def find_user(email:)
    @users.find { |u| u['profile']['email'].eql?(email) }
  end

  def post_message_to_user(email:, text:)
    user = find_user(email:)
    user_id = user['id']
    post_message(text:, channel: user_id)
  end
end
