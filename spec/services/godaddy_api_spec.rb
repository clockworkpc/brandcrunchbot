require 'rails_helper'

# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
RSpec.describe GodaddyApi, type: :service do
  let(:api) { described_class.new }
  let(:https) { instance_double(Net::HTTP) }
  let(:request) { instance_double(Net::HTTP::Post) }

  describe '#get_auction_details_by_domain_name' do
    let(:xml) { Rails.root.join('spec/fixtures/godaddy/get_auction_details_success.xml').read }
    let(:response) { instance_double(Net::HTTPResponse, body: xml) }

    before do
      allow(api).to receive(:new_soap_request)
        .with(soap_action_name: 'GetAuctionDetailsByDomainName', basename: 'get_auction_details_by_domain_name', kwargs: { domain_name: 'example.com' })
        .and_return([https, request])
      allow(https).to receive(:request).with(request).and_return(response)
    end

    it 'returns a hash with the auction details attributes' do
      result = api.get_auction_details_by_domain_name(domain_name: 'example.com')
      expect(result).to include('DomainName' => 'example.com', 'IsValid' => 'True')
    end
  end

  describe '#get_auction_details' do
    let(:domain_name) { 'example.com' }
    let(:xml) do
      Rails.root.join('spec/fixtures/godaddy/get_auction_details_success.xml').read.gsub('example.com', domain_name)
    end
    let(:response) { instance_double(Net::HTTPResponse, body: xml) }

    before do
      allow(api).to receive(:new_soap_request)
        .with(soap_action_name: 'GetAuctionDetails', basename: 'get_auction_details', kwargs: { domain_name: domain_name })
        .and_return([https, request])
      allow(https).to receive(:request).with(request).and_return(response)
      allow(Rails.logger).to receive(:info)
    end

    it 'logs and returns the parsed auction details' do
      result = api.get_auction_details(domain_name: domain_name)
      expect(Rails.logger).to have_received(:info).with(kind_of(Hash))
      expect(result).to include('DomainName' => domain_name)
    end
  end

  describe '#estimate_closeout_domain_price' do
    let(:xml) do
      Rails.root.join('spec/fixtures/godaddy/estimate_closeout_domain_price_success.xml').read
        .gsub('example.com', 'bar.com')
    end
    let(:response) { instance_double(Net::HTTPResponse, body: xml, code: '200') }

    before do
      allow(api).to receive(:new_soap_request)
        .with(soap_action_name: 'EstimateCloseoutDomainPrice', basename: 'estimate_closeout_domain_price', kwargs: { domain_name: 'bar.com', add_privacy: false })
        .and_return([https, request])
      allow(https).to receive(:request).with(request).and_return(response)
      allow(Rails.logger).to receive(:info)
    end

    it 'returns a symbol-keyed hash with expected fields' do
      result = api.estimate_closeout_domain_price(domain_name: 'bar.com')
      expect(result).to include(
        result: 'Success',
        domain: 'bar.com',
        price: a_kind_of(Integer),
        closeout_domain_price_key: a_kind_of(String)
      )
    end

    it 'returns nil if response code is not 200' do
      allow(response).to receive(:code).and_return('500')
      expect(api.estimate_closeout_domain_price(domain_name: 'bar.com')).to eq({})
    end
  end

  describe '#get_auction_list' do
    let(:xml) { Rails.root.join('spec/fixtures/godaddy/get_auction_list_success.xml').read }
    let(:response) { instance_double(Net::HTTPResponse, body: xml) }

    before do
      allow(api).to receive(:new_soap_request)
        .with(soap_action_name: 'GetAuctionList', basename: 'get_auction_list', kwargs: { page_number: 1, rows_per_page: 5, begins_with_keyword: 'ex' })
        .and_return([https, request])
      allow(https).to receive(:request).with(request).and_return(response)
    end

    it 'returns an array of auction hashes with symbol keys' do
      list = api.get_auction_list(page_number: 1, rows_per_page: 5, begins_with_keyword: 'ex')
      expect(list).to be_an(Array)
      expect(list.first).to have_key(:domain_name)
      expect(list.first[:price]).to be_a(Integer)
    end
  end

  describe '#place_bid_or_purchase' do
    let(:xml) { Rails.root.join('spec/fixtures/godaddy/get_auction_list_success.xml').read }
    let(:response) { instance_double(Net::HTTPResponse, body: xml, code: '200') }

    before do
      allow(api).to receive(:new_soap_request)
        .with(soap_action_name: 'PlaceBidOrPurchase', basename: 'place_bid_or_purchase', kwargs: hash_including(domain_name: 'baz.com', s_bid_amount: '10'))
        .and_return([https, request])
      allow(https).to receive(:request).with(request).and_return(response)
    end

    it 'parses and returns the auction list response' do
      result = api.place_bid_or_purchase(domain_name: 'baz.com', s_bid_amount: '10')
      expect(result).to be_an(Array)
      expect(result.first).to include(:domain_name)
    end
  end

  describe '#purchase_instantly' do
    let(:inst_resp) { instance_double(Net::HTTPResponse, body: 'purchased') }

    before do
      allow(api).to receive(:estimate_closeout_domain_price)
        .with(domain_name: 'qux.com').and_return(closeout_domain_price_key: 'KEY123')
      allow(api).to receive(:instant_purchase_closeout_domain)
        .with(domain_name: 'qux.com', closeout_domain_price_key: 'KEY123').and_return(inst_resp)
    end

    it 'returns ok: false when no key present' do
      allow(api).to receive(:estimate_closeout_domain_price).and_return({})
      result = api.purchase_instantly(domain_name: 'qux.com')
      expect(result).to eq(ok: false)
    end

    it 'delegates to instant_purchase_closeout_domain when key present' do
      result = api.purchase_instantly(domain_name: 'qux.com')
      expect(result).to eq(inst_resp)
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/MultipleMemoizedHelpers
