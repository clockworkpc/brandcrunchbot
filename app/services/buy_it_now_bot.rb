class BuyItNowBot < ApplicationJob
  queue_as :default

  def gda
    @gda ||= GodaddyApi.new
  end

  def parse_instant_purchase_response(response)
    return { 'Result' => 'Failure' } if response.is_a?(Hash) && response[:ok] == false

    doc = Nokogiri::XML(response.body)
    Rails.logger.info(response.body)
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

    Rails.logger.info(auction_details)
    if auction_details['IsValid'] == 'False'
      result[:valid] = false
      return result
    end

    Rails.logger.info("auction_details: #{auction_details}")
    if auction_details['Price'].nil?
      result[:valid] = false
      return result
    end

    result
  end

  def purchase_outright(domain_name:, attempts: 5)
    result = { valid: true, rescheduled: false, success: false }
    attempts.times do
      cdpr = gda.estimate_closeout_domain_price(domain_name:)
      Rails.logger.info(cdpr)
      next unless cdpr.is_a?(Hash)

      next if cdpr[:result] == 'Failure'

      closeout_domain_price_key = cdpr[:closeout_domain_price_key]
      Rails.logger.info("Close Out Key: #{closeout_domain_price_key}")

      response = gda.instant_purchase_closeout_domain(domain_name:, closeout_domain_price_key:)
      Rails.logger.info(response)
      Rails.logger.info(response.body)

      if response&.status == 200
        result[:success] = true
        return result
      end
    end
    result[:valid] = false
    result
  end

  def count_down_until(domain_name:, auction_end_time:, secs_f:)
    while Time.now.utc < auction_end_time.utc
      remaining_time = auction_end_time - Time.now.utc
      text = "Time remaining in auction for #{domain_name} until #{auction_end_time}: #{format('%.6f', remaining_time)} seconds" # rubocop:disable Metrics/LineLength
      Rails.logger.info(text.yellow)
      sleep_time = [remaining_time, secs_f].min
      sleep(sleep_time)
    end
  end

  def perform(auction, auction_end_time = nil)
    domain_name = auction.domain_name

    # Check whether still a valid Auction
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

    # Make up to 5 rapid attempts to purchase
    attempts = ENV.fetch('BUY_IT_NOW_ATTEMPTS', 5).to_i
    purchase_outright(domain_name:, attempts:)
  end

  # def perform(auction, auction_end_time = nil)
  #   api_rate_limiter = ApiRateLimiter.new
  #   domain_name = auction.domain_name
  #   # bin_price = auction.bin_price
  #   # counter = ENV.fetch('BUY_IT_NOW_COUNTER', 10).to_i
  #   attempts = ENV.fetch('BUY_IT_NOW_ATTEMPTS', 5).to_i
  #
  #   auction_details = gda.get_auction_details(domain_name:)
  #   datetime_str = auction_details['AuctionEndTime']
  #   auction_end_time = Utils.convert_to_utc(datetime_str:) if auction_end_time.nil?
  #
  #   Rails.logger.info("Validating auction for #{domain_name}")
  #   initial_check = check_auction(auction_details:)
  #   return if initial_check[:valid] == false

  # Rails.logger.info("Auction validated for #{domain_name}")
  #
  # count_down_until(
  #   domain_name:,
  #   auction_end_time: auction_end_time + 0.25,
  #   secs_f: ENV.fetch('BUY_IT_NOW_SLEEP', 1).to_f
  # )

  # running = true
  # while running
  # counter -= 1
  # Rails.logger.info("Domain Name: #{domain_name}, Counter: #{counter}")
  # break if counter.zero?

  # result = api_rate_limiter.limit_rate(
  #   method(:purchase_outright),
  #   domain_name:,
  #   attempts:
  # )

  # Domain has been purchased (200 and some other conditions)
  # break if result[:success] == true

  # Domain not available anymore
  # break if result[:valid] == false

  # Reschedule for future Auction
  # break if result[:rescheduled] == true

  # sleep ENV.fetch('BUY_IT_NOW_SLEEP', 0.5).to_f
  # end
  #   end
end

# def purchase_or_ignore(domain_name:, bin_price:, skip_validation: false, cdpr: nil)
#   if skip_validation
#     Rails.logger.info("Skipping validation of Auction, attempting instant purchase for #{domain_name}")
#     result = { valid: true, rescheduled: false, success: false }
#     closeout_domain_price_key = cdpr[:closeout_domain_price_key]
#     Rails.logger.info("Closeout Key: #{closeout_domain_price_key}")
#     response = gda.instant_purchase_closeout_domain(domain_name:, closeout_domain_price_key:)
#
#     Rails.logger.info(response)
#     Rails.logger.info(response.body)
#     result[:valid] = false
#     return response

# hsh = parse_instant_purchase_response(response)
# if hsh['Result'] == 'Success'
#   Rails.logger.info("Successful purchase of #{domain_name}".green)
#   result[:success] = true
# else
#   Rails.logger.info('No purchase made'.red)
#   result[:valid] = false
# end
# else
# auction_details = gda.get_auction_details(domain_name:)
# result = check_auction(auction_details:)
# return result unless result[:valid] == true

#     price = auction_details['Price'].sub('$', '').to_i
#
#     if price <= bin_price
#       Rails.logger.info "I will buy this domain at #{price}"
#       response = gda.purchase_instantly(domain_name:)
#       hsh = parse_instant_purchase_response(response)
#       if hsh['Result'] == 'Success'
#         Rails.logger.info("Successful purchase of #{domain_name}".green)
#         result[:success] = true
#       else
#         Rails.logger.info('No purchase made'.red)
#         result[:valid] = false
#       end
#
#     else
#       Rails.logger.info "Price #{price} is higher than BIN price #{bin_price}"
#       datetime_str = auction_details['AuctionEndTime']
#       auction_end_time = Utils.convert_to_utc(datetime_str:)
#       auction = Auction.find_by(domain_name:)
#       auction.update!(auction_end_time:)
#       # dt = Utils.convert_to_utc(datetime_str: auction_end_time)
#
#       job_enqueued = scheduled_job(auction)
#       extant_job = job_enqueued&.run_at && job_enqueued.run_at > Time.now.utc
#       result[:rescheduled] = true
#       if extant_job
#         Rails.logger.info("Job already scheduled for #{domain_name} at #{job_enqueued.run_at}".yellow)
#         return result
#       end
#
#       Rails.logger.info "Scheduling a job for #{auction_end_time}"
#       self.class.set(wait_until: auction_end_time - 5.seconds).perform_later(auction)
#       Rails.logger.info "Will try again at #{auction_end_time}".yellow
#     end
#   end
#   result
# end
