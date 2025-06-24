class FiftyDollarBinBot < ApplicationJob
  queue_as :default

  MAX_ATTEMPTS = ENV.fetch('FIFTY_DOLLAR_BIN_ATTEMPTS', 600).to_i     # 10 minutes at 1s interval = 600
  INTERVAL = ENV.fetch('FIFTY_DOLLAR_BIN_INTERVAL', 5).to_f           # 5 seconds = 12 calls/minute

  def gda
    @gda ||= GodaddyApi.new
  end

  def check_auction(auction_details:)
    result = { valid: true }

    result[:valid] = false if auction_details['IsValid'] == 'False' || auction_details['Price'].nil?

    result
  end

  def perform(auction)
    domain_name = auction.domain_name
    Rails.logger.info("[$50 BIN] Starting monitoring for #{domain_name}")

    MAX_ATTEMPTS.times do |i|
      sleep INTERVAL
      Rails.logger.info("[$50 BIN] Attempt ##{i + 1} for #{domain_name}")

      auction_details = gda.get_auction_details(domain_name:)
      check = check_auction(auction_details:)

      next unless check[:valid]

      cdpr = gda.estimate_closeout_domain_price(domain_name:)
      next unless cdpr.is_a?(Hash) && cdpr[:result] == 'Success'

      key = cdpr[:closeout_domain_price_key]
      response = gda.instant_purchase_closeout_domain(domain_name:, closeout_domain_price_key: key)

      parsed = parse_instant_purchase_response(response)
      if parsed['Result'] == 'Success'
        Rails.logger.info("[$50 BIN] Purchase SUCCESS for #{domain_name}")
        return
      else
        Rails.logger.info("[$50 BIN] Purchase attempt failed for #{domain_name}")
      end
    end

    Rails.logger.warn("[$50 BIN] Gave up after #{MAX_ATTEMPTS} attempts for #{domain_name}")
  end

  def parse_instant_purchase_response(response)
    raise 'Response indicates failure' if response.is_a?(Hash) && response[:ok] == false

    doc = Nokogiri::XML(response.body)
    namespaces = {
      'soap' => 'http://www.w3.org/2003/05/soap-envelope',
      'ns' => 'GdAuctionsBiddingWSAPI_v2'
    }

    result_node = doc.at_xpath('//ns:EstimateCloseoutDomainPriceResult/Result', namespaces)
    raise 'Missing EstimateCloseoutDomainPriceResult/Result node' unless result_node

    inner_doc = Nokogiri::XML(result_node.text)
    purchase_node = inner_doc.at_xpath('//InstantPurchaseCloseoutDomain')
    raise 'Missing InstantPurchaseCloseoutDomain node in inner XML' unless purchase_node

    purchase_node
      .elements
      .each_with_object({}) { |child, hash| hash[child.name] = child.text }
  end
end
