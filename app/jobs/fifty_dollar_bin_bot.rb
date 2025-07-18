class FiftyDollarBinBot < ApplicationJob
  queue_as :default

  MAX_ATTEMPTS = ENV.fetch('FIFTY_DOLLAR_BIN_ATTEMPTS', 600).to_i     # 10 minutes at 1s interval = 600
  INTERVAL = ENV.fetch('FIFTY_DOLLAR_BIN_INTERVAL', 5).to_f           # 5 seconds = 12 calls/minute

  def gda
    @gda ||= GodaddyApi.new
  end

  def check_auction(auction_details:)
    Rails.logger.info("Auction details: #{auction_details.inspect}")
    result = { valid: true }

    result[:valid] = false if auction_details['IsValid'] == 'False' || auction_details['Price'].nil?

    result
  end

  def parse_instant_purchase_response(response)
    raise 'Response indicates failure' if response.is_a?(Hash) && response[:ok] == false

    doc = Nokogiri::XML(response.body)
    namespaces = {
      'soap' => 'http://www.w3.org/2003/05/soap-envelope',
      'ns' => 'GdAuctionsBiddingWSAPI_v2'
    }

    result_node = doc.at_xpath('//ns:InstantPurchaseCloseoutDomainResponse/ns:InstantPurchaseCloseoutDomainResult', namespaces)
    raise 'Missing InstantPurchaseCloseoutDomainResult node' unless result_node

    inner_xml = result_node.text
    inner_doc = Nokogiri::XML(inner_xml)
    domain_node = inner_doc.at_xpath('//InstantPurchaseCloseoutDomain')
    raise 'Missing InstantPurchaseCloseoutDomain node in inner XML' unless domain_node

    domain_node.attributes.transform_values(&:value)
  end

  def stop_requested?(domain_name)
    Rails.cache.read("stop_bot:#{domain_name}") == true
  end

  def attempt_purchase(domain_name)
    Rails.logger.info("MAX_ATTEMPTS = #{MAX_ATTEMPTS}")
    MAX_ATTEMPTS.times do |i|
      break if stop_requested?(domain_name)

      sleep INTERVAL
      Rails.logger.info("[$50 BIN] Attempt ##{i + 1} for #{domain_name}")

      auction_details = gda.get_auction_details(domain_name:)
      check = check_auction(auction_details:)
      next unless check[:valid]

      cdpr = gda.estimate_closeout_domain_price(domain_name:)
      next unless cdpr.is_a?(Hash) && cdpr[:result] == 'Success'

      closeout_domain_price_key = cdpr[:closeout_domain_price_key]
      response = gda.instant_purchase_closeout_domain(domain_name:, closeout_domain_price_key:)

      parsed = parse_instant_purchase_response(response)
      Rails.logger.info("[$50 BIN] Instant purchase response: #{parsed.inspect}")
      return true if parsed['Result'] == 'Success'

      Rails.logger.info("[$50 BIN] Purchase attempt failed for #{domain_name}")
    end

    false
  end

  def count_down_until(domain_name:, auction_end_time:, secs_f:)
    while Time.now.utc < auction_end_time.utc
      remaining_time = auction_end_time - Time.now.utc
      text = "Time remaining in auction for #{domain_name} until #{auction_end_time}: #{format('%.6f', remaining_time)} seconds"
      Rails.logger.info(text.yellow)
      sleep_time = [remaining_time, secs_f].min
      sleep(sleep_time)
    end
    true
  end

  def preliminary_validation(domain_name:, auction_end_time: nil)
    auction_details = gda.get_auction_details(domain_name:)
    datetime_str = auction_details['AuctionEndTime']
    auction_end_time = Utils.convert_to_utc(datetime_str:) if auction_end_time.nil?
    Rails.logger.info("Validating auction for #{domain_name}")
    initial_check = check_auction(auction_details:)
    return false if initial_check[:valid] == false

    Rails.logger.info("Auction validated for #{domain_name}")
    countdown_delay = ENV.fetch('BUY_IT_NOW_BOT_DELAY', 0.4).to_f

    # Count down until 0.25 seconds after the Auction ends
    count_down_until(
      domain_name:,
      auction_end_time: auction_end_time + countdown_delay,
      secs_f: ENV.fetch('BUY_IT_NOW_SLEEP', 1).to_f
    )
  end

  def perform(auction, _auction_end_time = nil)
    domain_name = auction.domain_name
    Rails.logger.info("[$50 BIN] Starting monitoring for #{domain_name}")

    # Check whether still a valid Auction
    # still_valid = preliminary_validation(domain_name:, auction_end_time:)
    # return unless still_valid

    if attempt_purchase(domain_name)
      Rails.logger.info("[$50 BIN] Purchase SUCCESS for #{domain_name}")
      auction.update!(purchase_status: 'purchased')
    else
      Rails.logger.warn("[$50 BIN] Gave up after #{MAX_ATTEMPTS} attempts for #{domain_name}")
      auction.update!(purchase_status: 'failed')
    end
  end
end
