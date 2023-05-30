require 'rails_helper'

RSpec.describe GodaddyApi do
  before(:all) do
    @service = described_class.new
  end

  describe 'Domain Info' do
    it 'GetAuctionDetailsByDomainName', focus: false do
      domain_name = 'cannaphresh.com'
      res = @service.get_auction_details_by_domain_name(domain_name:)
      res.each do |k, v|
        puts Rainbow("#{k}: #{v}").orange
      end
    end

    it 'GetAuctionDetails', focus: false do
      domain_name = 'cannaphresh.com'
      res = @service.get_auction_details(domain_name:)
      res.each do |k, v|
        puts Rainbow("#{k}: #{v}").orange
      end
    end
  end

  describe 'Auction List' do
    it 'GetAuctionList', focus: true do
      page_number = 1
      rows_per_page = 100
      begins_with_keyword = ''
      res = @service.get_auction_list(page_number:, rows_per_page:, begins_with_keyword:)
      pp res
    end
  end

  describe 'Purchase Closeout' do
    it 'instantly purchases a domain', focus: false do
      domain_name = 'cannaphresh.com'
    end
  end
end
