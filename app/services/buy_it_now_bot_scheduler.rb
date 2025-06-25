require 'time'

class BuyItNowBotScheduler
  def initialize(gda: GodaddyApi.new)
    @gsa = GoogleSheetsApi.new
    @gda = gda
    @bb = BuyItNowBot.new(gda: @gda)
  end

  def update_active_auctions(changes:)
    return if changes.blank?

    changes.each do |hsh|
      Rails.logger.info(hsh)
      domain_name = hsh['domain_name']
      bin_price = hsh['bin_price']

      auction = if Auction.exists?(domain_name:)
                  Auction.find_by(domain_name:)
                else
                  Auction.create(domain_name:, bin_price:)
                end
      auction.update(bin_price:, active: true)
    end
  end

  def deactivate_passe_auctions(values:)
    # TODO: Delete delayed job associated with this auction
    domains_in_spreadsheet = values.map(&:first)
    domains_in_database = Auction.all.map(&:domain_name)
    redundant_domains = domains_in_database.uniq - domains_in_spreadsheet
    redundant_domains.each do |domain_name|
      auction = Auction.find_by(domain_name:)
      auction.update!(active: false)
    end
  end

  def convert_to_utc(res:)
    datetime_str = res['AuctionEndTime']
    return unless datetime_str

    Utils.convert_to_utc(datetime_str:)
  end

  def fetch_auction_details(auction:)
    Rails.logger.info("auction: #{auction}")
    domain_name = auction[:domain_name]
    res = @gda.get_auction_details(domain_name:)
    Rails.logger.info("res: #{res}")
    is_valid = res['IsValid'].downcase == 'true'

    if is_valid
      auction_end_time = convert_to_utc(res:)
      Rails.logger.info("END TIME: #{auction_end_time}, now #{DateTime.now.utc}".red)
      price = res['Price'].scan(/\d+/).first.to_i
      auction.update!(is_valid:, auction_end_time:, price:)
    else
      auction.update!(is_valid:)
    end

    Auction.find_by(domain_name:)
  end

  def schedule_buy_it_now_bot(auction:, auction_end_time: nil)
    auction_end_time ||= Utils.convert_to_utc(datetime_str: auction.auction_end_time)
    Rails.logger.info(auction_end_time.class)
    Rails.logger.info(auction_end_time.to_s.green)
    Rails.logger.info((auction_end_time - 10).to_s.green)
  if auction.bin_price < 50
    BuyItNowBot.set(wait_until: auction_end_time - 10.seconds).perform_later(auction, auction_end_time)
  else
    FiftyDollarBinBot.set(wait_until: auction_end_time - 10.seconds).perform_later(auction, auction_end_time)
    end
  end

  def schedule_job(auction:)
    return unless auction.is_valid

    updated_auction = fetch_auction_details(auction:)
    return unless updated_auction.is_valid

    Rails.logger.info("updated_auction: #{updated_auction}")
    delayed_job = Delayed::Job.where('handler LIKE ?', "%#{auction.domain_name}%").first

    if delayed_job
      text = "JOB EXISTS for #{auction.domain_name} at #{delayed_job.run_at}"
      Rails.logger.info(text.red)
      return
    end

    Rails.logger.info("NO JOB EXISTS for #{auction.domain_name}".red)
    auction_end_time = updated_auction.auction_end_time
    schedule_buy_it_now_bot(auction: updated_auction, auction_end_time:)
  rescue StandardError => e
    Rails.logger.info(e)
  end

  def call(changes:)
    Delayed::Job.delete_all
    Auction.where(active: true).find_each do |auction|
      auction.update!(active: false)
    end
    update_active_auctions(changes:)
    active_auctions = Auction.where(active: true)
    active_auctions.each do |auction|
      schedule_job(auction:)
      sleep 0.25
    end
  end
end
