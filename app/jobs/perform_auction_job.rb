class PerformAuctionJob < ApplicationJob
  queue_as :default

  def perform(domain_name, s_bid_amount)
    ga = GodaddyApi.new

    limit = 10
    running = true
    while running
      res = ga.place_bid_or_purchase(domain_name:, s_bid_amount:)
      break if res == 'foo'

      limit -= 1
      break if limit.zero?

      sleep 1
    end
  end
end
