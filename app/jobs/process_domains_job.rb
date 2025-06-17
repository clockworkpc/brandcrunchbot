class ProcessDomainsJob < ApplicationJob
  queue_as :default

  def perform(changes)
    ga = GodaddyApi.new
    changes.each do |key, value|
      next unless key.match?('C1') && value.present?

      domain_name = value
      auction_details = ga.get_auction_details(domain_name:)
      auction_end_time_str = auction_details['AuctionEndTime']
      auction_end_time = DateTime.parse(auction_end_time_str)
      schedule_job(auction_end_time, domain_name)
    end
  end

  private

  def schedule_job(auction_end_time, domain_name)
    run_time = auction_end_time - 5.seconds
    PerformAuctionJob.set(wait_until: run_time).perform_later(domain_name)
  end
end
