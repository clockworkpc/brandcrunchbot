require 'rails_helper'

RSpec.describe GodaddyApi do
  before(:all) do
    @service = described_class.new
  end

  let(:auction_details_response) do
    { 'IsValid' => 'True',
      'DomainName' => 'alephdigital.com',
      'AuctionEndTime' => '10/01/2024 10:11 AM (PDT)',
      'BidCount' => '1',
      'Price' => '$10',
      'ValuationPrice' => '$2,017',
      'Traffic' => '0',
      'CreateDate' => '08/27/2014',
      'BidIncrementAmount' => '$5',
      'AuctionModel' => 'Bid',
      'AuditDateTime' => '9/30/2024 11:46:45 AM',
      'IsHighestBidder' => 'False' }.to_json
  end

  let(:successful_instant_purchase) do
    { 'Result' => 'Success',
      'Domain' => 'joinidentity.com',
      'Price' => '$11.00',
      'RenewalPrice' => '$10.99',
      'PrivateRegistration' => 'N/A',
      'ICANNFee' => '$0.18',
      'Taxes' => '$0.00',
      'Total' => '$22.17',
      'OrderID' => '3334609888' }
  end
  # describe '#get_auction_details' do
  #   it 'parses the auction details correctly' do
  #     domain_name = 'gourmetbunny.com'
  #
  #     # Stub the SOAP request
  #     stub_request(:post, 'https://example.com/soap_endpoint') # Replace with actual SOAP endpoint
  #       .with(body: /GetAuctionDetails/) # Match the SOAP action name
  #       .to_return(status: 200, body: auction_details_response, headers: {})
  #
  #     # Create an instance of the service and call the method
  #     service = described_class.new
  #     result = service.get_auction_details(domain_name:)
  #
  #     # Expect the parsed result to match the auction details
  #     expect(result).to eq(JSON.parse(auction_details_response))
  #   end
  # end

  describe 'Domain Info' do
    it 'GetAuctionDetailsByDomainName' do
      domain_name = 'gourmetbunny.com'
      res = @service.get_auction_details_by_domain_name(domain_name:)
      expect(res).to eq(auction_details)
    end

    it 'GetAuctionDetails', focus: false do
      domain_name = 'alephdigital.com'
      # allow(@service)
      #   .to receive(:get_auction_details)
      #   .with(domain_name:)
      #   .and_return(auction_details)
      #
      # Invoke the method
      res = @service.get_auction_details(domain_name:)
      require 'pry'; binding.pry

      # Expect the response to match the stubbed auction details
      expect(res).to eq(auction_details)
    end
  end

  describe 'Auction List' do
    it 'GetAuctionList', focus: false do
      page_number = 1
      rows_per_page = 100
      begins_with_keyword = 'ubi'
      res = @service.get_auction_list(page_number:, rows_per_page:, begins_with_keyword:)
      pp res
    end
  end

  describe 'Place Bid or Purchase' do
    it 'places a bid on or purchases a domain', focus: false do
      domain_name = '19ventures.com'
      s_bid_amount = 5

      details = @service.get_auction_details(domain_name:)

      res = @service.place_bid_or_purchase(domain_name:, s_bid_amount:)
      pp res
    end
  end

  describe 'Purchasing at Buy It Now price' do
    it 'gets the key from EstimateCloseoutDomainPrice' do
      domain_name = 'wincademy.com'
      # expect { @service.estimate_closeout_domain_price(domain_name:) }.not_to raise_error
      res = @service.estimate_closeout_domain_price(domain_name:)
      key = res[:closeout_domain_price_key]
      expect(key).to match(/[a-zA-Z0-9]/)
      expect(key.length).to eq(168)
    end

    it 'gets the key from the EstimateCloseoutDomainPrice and purchases the domain' do
      domain_name = 'wincademy.com'
      cdpr = @service.estimate_closeout_domain_price(domain_name:)
      closeout_domain_price_key = cdpr[:closeout_domain_price_key]
      res = @service.instant_purchase_closeout_domain(domain_name:, closeout_domain_price_key:)
    end
  end
end
