class BuyItNowBot
  def initialize
    @gda = GodaddyApi.new
  end

  def call(domain_name:, target_price:)
    counter = 3
    running = true
    while running
      auction_details = @gda.get_auction_details(domain_name:)
      pp auction_details
      price = auction_details['Price'].sub('$', '').to_i

      return if counter.zero?

      if price <= target_price
        puts "I will buy this domain at #{price}"
        counter = 0
      else
        puts "I will not buy this domain at #{price}"
        counter -= 1
        puts ''
        puts 'Trying again...'
        puts ''
      end

      sleep 2
    end
  end
end
