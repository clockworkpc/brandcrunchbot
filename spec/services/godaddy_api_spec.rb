require 'rails_helper'

RSpec.describe GodaddyApi do
  before(:all) do
    @service = described_class.new
  end

  describe 'Domain Info' do
    it 'GetAuctionDetailsByDomainName', focus: false do
      domain_name = 'gourmetbunny.com'
      res = @service.get_auction_details_by_domain_name(domain_name:)
      res.each do |k, v|
        puts Rainbow("#{k}: #{v}").orange
      end
    end

    it 'GetAuctionDetails', focus: false do
      domain_name = 'gourmetbunny.com'
      res = @service.get_auction_details(domain_name:)
      res.each do |k, v|
        puts Rainbow("#{k}: #{v}").orange
      end
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

      require 'pry'; binding.pry

      res = @service.place_bid_or_purchase(domain_name:, s_bid_amount:)
      pp res
    end
  end
end
