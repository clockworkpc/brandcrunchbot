require 'rails_helper'

RSpec.describe GodaddyApi do
  let(:api) { described_class.new }

  describe '#get_auction_details' do
    it 'parses the auction details correctly' do
      fake_response = instance_double(Net::HTTPResponse, body: File.read(Rails.root.join('spec/fixtures/godaddy/get_auction_details.xml')))
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(fake_response)

      result = api.get_auction_details(domain_name: 'example.com')
      expect(result).to include('DomainName' => 'example.com')
    end
  end

  describe '#estimate_closeout_domain_price' do
    it 'parses the estimate price correctly' do
      fake_response = instance_double(Net::HTTPResponse, body: File.read(Rails.root.join('spec/fixtures/godaddy/estimate_closeout_domain_price.xml')), code: '200')
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(fake_response)

      result = api.estimate_closeout_domain_price(domain_name: 'example.com')
      expect(result).to include(:domain, :price, :closeout_domain_price_key)
    end
  end

  describe '#get_auction_list' do
    it 'parses the auction list correctly' do
      fake_response = instance_double(Net::HTTPResponse, body: File.read(Rails.root.join('spec/fixtures/godaddy/get_auction_list.xml')))
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(fake_response)

      result = api.get_auction_list(page_number: 1, rows_per_page: 10, begins_with_keyword: 'ex')
      expect(result).to be_an(Array)
      expect(result.first).to include(:domain_name)
    end
  end

  describe '#place_bid_or_purchase' do
    it 'parses the purchase response correctly' do
      fake_response = instance_double(Net::HTTPResponse, body: File.read(Rails.root.join('spec/fixtures/godaddy/place_bid_or_purchase.xml')))
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(fake_response)

      result = api.place_bid_or_purchase(domain_name: 'example.com', s_bid_amount: '10')
      expect(result).to be_an(Array)
    end
  end

  describe '#purchase_instantly' do
    it 'executes the full flow and returns the result' do
      estimate_response = instance_double(Net::HTTPResponse, body: File.read(Rails.root.join('spec/fixtures/godaddy/estimate_closeout_domain_price.xml')), code: '200')
      purchase_response = instance_double(Net::HTTPResponse, body: File.read(Rails.root.join('spec/fixtures/godaddy/instant_purchase_closeout_domain.xml')))

      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(estimate_response, purchase_response)

      result = api.purchase_instantly(domain_name: 'example.com')
      expect(result).to be_present
    end
  end
end
