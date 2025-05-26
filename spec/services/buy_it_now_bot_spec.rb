require 'rails_helper'

RSpec.describe BuyItNowBot do
  before do
    @service = described_class.new
    domain_name = 'rewardscrm.com'
    bin_price = 5
    @auction = Auction.create!(domain_name:, bin_price:)
  end

  it 'attempts to purchase a given domain' do
    # reload!
    # @service = BuyItNowBot.new
    # domain_name = 'rewardscrm.com'
    # bin_price = 5
    # @auction = Auction.create!(domain_name:, bin_price:)

    auction_end_time = Time.now.utc + 3
    @service.perform(@auction, auction_end_time)
  end
end
