class BuyItNowBot < ApplicationJob
  queue_as :default

  def gda
    @gda ||= GodaddyApi.new
  end

  # app/jobs/buy_it_now_bot.rb
  def parse_instant_purchase_response(response)
    return { 'Result' => 'Failure' } if response.is_a?(Hash) && response[:ok] == false

    doc = Nokogiri::XML(response.body)
    namespaces = {
      'soap' => 'http://www.w3.org/2003/05/soap-envelope',
      'ns' => 'GdAuctionsBiddingWSAPI_v2'
    }

    # grab the CDATA-wrapped fragment
    result_node = doc.at_xpath('//ns:EstimateCloseoutDomainPriceResult/Result', namespaces)
    xml_fragment = result_node.text

    # parse it into a small Nokogiri doc
    inner_doc = Nokogiri::XML(xml_fragment)
    ip_node   = inner_doc.at_xpath('//InstantPurchaseCloseoutDomain')

    # build a Hash of its child elements
    ip_node
      .elements
      .each_with_object({}) { |child, h| h[child.name] = child.text }
  end

  def scheduled_job(auction)
    # Fetch all jobs related to the BuyItNowBot class
    delayed_jobs = Delayed::Job.where('handler LIKE ?', '%BuyItNowBot%')

    # Check if any job matches the `auction_gid`
    delayed_jobs.detect do |job|
      job_wrapper = YAML.unsafe_load(job.handler)
      job_data = job_wrapper.job_data
      auction_gid = job_data['arguments'].first['_aj_globalid']
      auction_obj = GlobalID::Locator.locate(auction_gid)
      auction_obj.id == auction.id
    end
  end

  def check_auction(auction_details:)
    result = { valid: true, rescheduled: false, success: false }

    if auction_details['IsValid'] == 'False'
      result[:valid] = false
      return result
    end

    if auction_details['Price'].nil?
      result[:valid] = false
      return result
    end

    result
  end

  def purchase_outright(domain_name:, attempts_per_second: 4, total_attempts: nil, total_seconds: nil)
    total_attempts ||= attempts_per_second * total_seconds
    interval = 1.0 / attempts_per_second

    result = { valid: true, rescheduled: false, success: false }

    total_attempts.times do |i|
      sleep interval
      Rails.logger.info("Attempt ##{i + 1}")

      auction_details = gda.get_auction_details(domain_name:)
      initial_check = check_auction(auction_details:)
      next if initial_check[:valid] == false

      cdpr = gda.estimate_closeout_domain_price(domain_name:)
      next unless cdpr.is_a?(Hash) && cdpr[:result] == 'Success'

      closeout_domain_price_key = cdpr[:closeout_domain_price_key]
      gda.instant_purchase_closeout_domain(domain_name:, closeout_domain_price_key:)

      result[:success] = true
      return result
    end

    result[:valid] = false
    result
  end

  def count_down_until(domain_name:, auction_end_time:, secs_f:)
    while Time.now.utc < auction_end_time.utc
      remaining_time = auction_end_time - Time.now.utc
      text = "Time remaining in auction for #{domain_name} until #{auction_end_time}: #{format('%.6f', remaining_time)} seconds"
      Rails.logger.info(text.yellow)
      sleep_time = [remaining_time, secs_f].min
      sleep(sleep_time)
    end
  end

  def preliminary_validation(domain_name:, auction_end_time: nil)
    auction_details = gda.get_auction_details(domain_name:)
    datetime_str = auction_details['AuctionEndTime']
    auction_end_time = Utils.convert_to_utc(datetime_str:) if auction_end_time.nil?
    Rails.logger.info("Validating auction for #{domain_name}")
    initial_check = check_auction(auction_details:)
    return if initial_check[:valid] == false

    Rails.logger.info("Auction validated for #{domain_name}")
    countdown_delay = ENV.fetch('BUY_IT_NOW_BOT_DELAY', 0.4).to_f

    # Count down until 0.25 seconds after the Auction ends
    count_down_until(
      domain_name:,
      auction_end_time: auction_end_time + countdown_delay,
      secs_f: ENV.fetch('BUY_IT_NOW_SLEEP', 1).to_f
    )
  end

  def perform(auction, auction_end_time = nil)
    domain_name = auction.domain_name

    # Check whether still a valid Auction
    preliminary_validation(domain_name:, auction_end_time:)

    # Make up to 5 rapid attempts to purchase
    # End job if purchase attempt completed, be it successful or not
    attempts_per_second = ENV.fetch('BUY_IT_NOW_ATTEMPTS', 5).to_i
    result = purchase_outright(domain_name:, attempts_per_second:)
    return if result[:success] == true

    sleep 1
    Rails.logger.info("Follow up check for #{domain_name}")
    second_auction_details = gda.get_auction_details(domain_name:)
    second_check = check_auction(auction_details: second_auction_details)
    return unless second_check[:valid]

    purchase_outright(domain_name:, attempts_per_second: 2)
  end
end
