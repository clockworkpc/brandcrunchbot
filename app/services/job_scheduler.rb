class BuyItNowBotScheduler
  def initialize
    @sheet_id = Rails.application.credentials[:sheet_id]
    @gsa = GoogleSheetsApi.new
    @gda = GodaddyApi.new
    @bb = BuyItNowBot.new(gda: @gda)
  end

  # TODO: Retrieve domains from Google

  def retrieve_domains_from_google_sheet(range: 'domains!A1:C')
    spreadsheet_id = Rails.application.credentials[:sheet_id]
    @gsa.get_spreadsheet_values(spreadsheet_id:, range:)
  end

  def update_active_auctions(values:)
    values.each do |ary|
      domain = ary[0]
      proxy_bid = ary[1].to_i
      bin_price = ary[2].to_i

      auction = if Auction.exists?(domain:)
                  Auction.find_by(domain:)
                else
                  Auction.create(domain:, proxy_bid:, bin_price:)
                end
      auction.update(proxy_bid:, bin_price:)
    end
  end

  def deactivate_passe_auctions(values:)
    domains_in_spreadsheet = values.map(&:first)
    domains_in_database = Auction.all.map(&:domain)
    redundant_domains = domains_in_database - domains_in_spreadsheet
    redundant_domains.each do |domain|
      auction = Auction.find_by(domain:)
      auction.update!(active: false)
    end
  end

  def fetch_auction_details(auction:)
    domain_name = auction[:domain]
    res = @gda.get_auction_details(domain_name:)
    is_valid = res['isValid'].downcase == 'true'
    auction_end_time = DateTime.parse(res['AuctionEndTime'])
    price = res['Price'].scan(/\d+/).first.to_i
    auction.update!(is_valid:, auction_end_time:, price:)
    Auction.find_by(domain:)
  end

  def schedule_buy_it_now_bot(auction:)
    domain_name = auction.domain
    target_price = auction.bin_price
    auction_end_time = auction.auction_end_time
    @bb.delay(run_at: auction_end_time).call(domain_name:, target_price:)
  end

  def call(range: 'domains!A1:C')
    response = retrieve_domains_from_google_sheet(range:)
    values = response.values
    update_active_auctions(values:)
    deactivate_passe_auctions(values:)
    active_auctions = Auction.find_by(active: true)

    active_auctions.each do |auction|
      updated_auction = fetch_auction_details(domain:)
      schedule_buy_it_now_bot(auction: updated_auction)
    end
  end
end
