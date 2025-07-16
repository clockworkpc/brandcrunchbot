require 'rails_helper'

RSpec.describe NameBio do
  let(:api_email) { 'test@example.com' }
  let(:api_key) { 'testapikey' }

  before do
    allow(Rails.application.credentials.name_bio).to receive(:api_email).and_return(api_email)
    allow(Rails.application.credentials.name_bio).to receive(:api_key).and_return(api_key)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:info)
  end

  describe '#send_comps_request' do
    let(:domain) { 'example.com' }
    let(:api_url) { described_class::URL_COMPS }
    let(:response_body) do
      {
        'status' => 'success',
        'status_message' => '',
        'credits_remaining' => 1234,
        'domain' => domain,
        'sld' => 'example',
        'tld' => '.com',
        'keywords' => 'example',
        'comps' => [
          ['similar.com', '500000', '2019-01-01', 'Private'],
          ['domain.com', '450000', '2018-01-01', 'Private']
        ],
        'attributes' => [
          'English Word', 'High Search Volume', 'No Advertisers',
          'Extension .com', 'Exclude Hyphens', 'Exclude Numbers'
        ]
      }.to_json
    end

    before do
      stub_request(:post, api_url)
        .with(body: hash_including(domain:))
        .to_return(status: 200, body: response_body)
    end

    it 'returns structured comps data' do
      result = described_class.new.send_comps_request(domain: domain)
      expect(result['status']).to eq('success')
      expect(result['comps']).to be_an(Array)
      expect(result['comps'].first).to eq(['similar.com', '500000', '2019-01-01', 'Private'])
    end
  end
end
