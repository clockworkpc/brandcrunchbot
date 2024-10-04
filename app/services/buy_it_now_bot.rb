class BuyItNowBot
  def initialize(gda: false)
    @gda = gda || GodaddyApi.new
  end

  def purchase_or_ignore(domain_name:)
    auction_details = @gda.get_auction_details(domain_name:)
    puts("auction_details: #{auction_details}")
    return if auction_details['Price'].nil?

    price = auction_details['Price'].sub('$', '').to_i

    return if counter.zero?

    if price <= bin_price
      Rails.logger.info "I will buy this domain at #{price}"
      @gda.purchase_instantly(domain_name:)
    else
      Rails.logger.info "Price #{price} is higher than target price #{bin_price}"
      counter -= 1
      Rails.logger.info 'Trying again...'
    end
  end

  def call(auction) # rubocop:disable Metrics/MethodLength
    domain_name = auction.domain
    bin_price = auction.bin_price
    counter = 10
    running = true
    while running
      auction_details = @gda.get_auction_details(domain_name:)
      puts("auction_details: #{auction_details}")
      break if auction_details['Price'].nil?

      price = auction_details['Price'].sub('$', '').to_i

      return if counter.zero?

      if price <= bin_price
        Rails.logger.info "I will buy this domain at #{price}"
        @gda.purchase_instantly(domain_name:)
        break
      else
        Rails.logger.info "Price #{price} is higher than target price #{bin_price}"
        counter -= 1
        Rails.logger.info 'Trying again...'
      end

      sleep 1
    end
  end
end
