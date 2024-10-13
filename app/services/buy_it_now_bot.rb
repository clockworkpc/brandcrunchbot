class BuyItNowBot < ApplicationJob
  queue_as :default

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

  def scheduled_job(auction)
    # Fetch all jobs related to the BuyItNowBot class
    delayed_jobs = Delayed::Job.where('handler LIKE ?', '%BuyItNowBot%')

    # Check if any job has the auction with id 142 as an argument
    delayed_jobs.detect do |job|
      job_wrapper = YAML.safe_load(job.handler,
                                   permitted_classes: [ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper])
      job_data = job_wrapper.job_data
      auction_gid = job_data['arguments'].first['_aj_globalid']
      auction_obj = GlobalID::Locator.locate(auction_gid)
      auction_obj.id == auction.id
    end
  end

  def purchase_or_ignore(domain_name:, bin_price:)
    result = { valid: true, rescheduled: false, success: false }

    auction_details = @gda.get_auction_details(domain_name:)
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

    price = auction_details['Price'].sub('$', '').to_i

    if price <= bin_price
      Rails.logger.info "I will buy this domain at #{price}"
      response = @gda.purchase_instantly(domain_name:)
      hsh = parse_instant_purchase_response(response)
      if hsh['Result'] == 'Success'
        Rails.logger.info("Successful purchase of #{domain_name}".green)
        result[:success] = true
      else
        Rails.logger.info('No purchase made'.red)
        result[:valid] = false
      end

      result

    else
      Rails.logger.info "Price #{price} is higher than BIN price #{bin_price}"
      auction_end_time = auction_details['AuctionEndTime']
      auction = Auction.find_by(domain: domain_name)
      auction.update!(auction_end_time:)
      # dt = Utils.convert_to_utc(datetime_str: auction_end_time)

      job_enqueued = scheduled_job(auction)
      extant_job = job_enqueued&.run_at && job_enqueued.run_at > Time.now.utc
      return result if extant_job

      Rails.logger.info "Scheduling a job for #{auction_end_time}"
      self.class.set(wait_until: auction_end_time - 5.seconds).perform_later(auction)
      Rails.logger.info 'Trying again...'
      result[:rescheduled] = true
    end
    result
  end

  def perform(auction, gda = nil)
    @gda = gda || GodaddyApi.new

    domain_name = auction.domain
    bin_price = auction.bin_price
    counter = 10
    running = true
    while running
      counter -= 1
      Rails.logger.info("Domain: #{domain_name}, Counter: #{counter}")
      break if counter.zero?

      begin
        result = api_rate_limiter.limit_rate(
          method(:purchase_or_ignore), domain_name:, bin_price:
        )

        # Domain has been purchased (200 and some other conditions)
        break if result[:success] == true

        # Domain not available anymore
        break if result[:valid] == false

        # Reschedule for future Auction
        break if result[:rescheduled] == true

      # Domain has not been purchased because the price is too high
      # Continue trying until the counter gets to 0
      rescue StandardError => e
        Rails.logger.info(e)
      end

      sleep 0.5

    end
  end
end
