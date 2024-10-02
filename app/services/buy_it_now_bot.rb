class BuyItNowBot
  def initialize(gda: false)
    @gda = gda || GodaddyApi.new
  end

  def call(domain_name:, target_price:) # rubocop:disable Metrics/MethodLength
    counter = 10
    running = true
    while running
      auction_details = @gda.get_auction_details(domain_name:)
      Rails.logger.info auction_details
      price = auction_details['Price'].sub('$', '').to_i

      return if counter.zero?

      if price <= target_price
        Rails.logger.info "I will buy this domain at #{price}"
        s_bid_amount = price
        @gda.place_bid_or_purchase(domain_name:, s_bid_amount:)
        counter = 0
      else
        Rails.logger.info "Price #{price} is higher than target price #{target_price}"
        counter -= 1
        Rails.logger.info 'Trying again...'
      end

      sleep 1
    end
  end
end
