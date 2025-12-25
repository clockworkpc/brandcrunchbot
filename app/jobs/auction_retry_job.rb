class AuctionRetryJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("AuctionRetryJob starting at #{Time.current}")

    auctions_to_check.find_each do |auction|
      next unless should_check_auction?(auction)

      check_and_update_auction(auction)
      sleep 0.25 # Rate limiting (pattern from BuyItNowBotScheduler)
    end

    # Always reschedule (infinite loop until manually stopped)
    reschedule_next_check
  end

  private

  def auctions_to_check
    Auction.where(active: true, is_valid: false)
           .where.not(first_checked_at: nil)
  end

  def should_check_auction?(auction)
    return true if auction.last_checked_at.nil?

    age_hours = (Time.current - auction.created_at) / 1.hour

    if age_hours < 24
      # Check every hour for first 24 hours
      hours_since_check = (Time.current - auction.last_checked_at) / 1.hour
      hours_since_check >= 1
    else
      # Check daily after 24 hours
      days_since_check = (Time.current - auction.last_checked_at) / 1.day
      days_since_check >= 1
    end
  end

  def check_and_update_auction(auction)
    domain_name = auction.domain_name

    begin
      # Use the same API method from GodaddyApi
      res = GodaddyApi.new.get_auction_details_by_domain_name(domain_name: domain_name)
      is_valid = res['IsValid']&.downcase == 'true'

      auction.update!(last_checked_at: Time.current)

      if is_valid
        handle_newly_valid_auction(auction, res)
      else
        Rails.logger.info("Auction still invalid: #{domain_name}")
      end
    rescue StandardError => e
      Rails.logger.error("Error checking auction #{domain_name}: #{e.message}")
    end
  end

  def handle_newly_valid_auction(auction, api_response)
    # Extract auction details (pattern from BuyItNowBotScheduler#fetch_auction_details)
    auction_end_time = Utils.convert_to_utc(datetime_str: api_response['AuctionEndTime'])
    price = api_response['Price']&.scan(/\d+/)&.first&.to_i

    # Update auction to valid state
    auction.update!(
      is_valid: true,
      auction_end_time: auction_end_time,
      price: price
    )

    Rails.logger.info("Auction NOW VALID: #{auction.domain_name} - scheduling BuyItNowBot")

    # Schedule the purchase bot (reuse existing scheduler)
    scheduler = BuyItNowBotScheduler.new
    scheduler.schedule_job(auction: auction)
  end

  def reschedule_next_check
    # Schedule next run in 1 hour (aligns with hourly check strategy)
    AuctionRetryJob.set(wait: 1.hour).perform_later
    Rails.logger.info("AuctionRetryJob rescheduled for #{1.hour.from_now}")
  end
end
