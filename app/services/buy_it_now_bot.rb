class BuyItNowBot
  def initialize(gda: false)
    @gda = gda || GodaddyApi.new
  end

  def parse_instant_purchase_response(response)
    doc = Nokogiri::XML(response.body)
    namespaces = {
      'soap' => 'http://www.w3.org/2003/05/soap-envelope',
      'ns' => 'GdAuctionsBiddingWSAPI_v2'
    }
    response_node = doc.xpath('//ns:EstimateCloseoutDomainPriceResult', namespaces)
    xml_fragment = response_node.first.children.first.text

    Nokogiri::XML(xml_fragment)
            .xpath('//InstantPurchaseCloseoutDomain')
            .first.to_h
  end

  def purchase_or_ignore(domain_name:, bin_price:)
    auction_details = @gda.get_auction_details(domain_name:)
    Rails.logger.info(auction_details)
    return { valid: false } if auction_details['IsValid'] == 'False'

    Rails.logger.info("auction_details: #{auction_details}")
    return if auction_details['Price'].nil?

    price = auction_details['Price'].sub('$', '').to_i

    if price <= bin_price
      Rails.logger.info "I will buy this domain at #{price}"
      response = @gda.purchase_instantly(domain_name:)
      hsh = parse_instant_purchase_response(response)
      { success: true } if hsh['Result'] == 'Success'
    else
      Rails.logger.info "Price #{price} is higher than target price #{bin_price}"
      auction_end_time = auction_details['AuctionEndTime']
      auction = Auction.find_by(domain: domain_name)
      auction.update!(auction_end_time:)
      dt = Utils.convert_to_utc(datetime_str: auction_end_time)

      if !dt.today? && dt > DateTime.now
        Rails.logger.info "Scheduling a job for #{auction_end_time}"
        bot_instance = self.class.new
        bot_instance.delay(run_at: dt - 5).call(auction)
        return { rescheduled: true }
      end

      Rails.logger.info 'Trying again...'
    end
  end

  def call(auction)
    domain_name = auction.domain
    bin_price = auction.bin_price
    counter = 10
    running = true
    while running
      counter -= 1
      Rails.logger.info("Domain: #{domain_name}, Counter: #{counter}")
      break if counter.zero?

      begin
        result = purchase_or_ignore(domain_name:, bin_price:)
        # Domain not available anymore
        break if result[:valid] == false

        # Reschedule for future Auction
        break if result[:rescheduled] == true

        # Domain has been purchased (200 and some other conditions)
        break if result&.code.to_i == 200

        # Domain has not been purchased because the price is too high
        # Continue trying until the counter gets to 0
      rescue StandardError => e
        Rails.logger.info(e)
      end

      sleep 1

    end
  end
end
