class JobScheduler
  def initialize
    @sheet_id = Rails.application.credentials[:sheet_id]
    @gsa = GoogleSheetsApi.new
    @gda = GodaddyApi.new
  end

  def retrieve_domains_from_google_sheet(domain_range:)
    spreadsheet_id = Rails.application.credentials[:sheet_id]
    range = domain_range
    res = @gsa.get_spreadsheet_values(spreadsheet_id:, range:)
    res.values[1..-1].map do |ary|
      hsh = {
        domain: ary[0],
        proxy_bid: ary[1].to_i,
        bin_price: ary[2].to_i
      }
      Auction.find_or_create(hsh)
    end
  end

  def call(domain:, list_range:, report_range: 'reports')
  end
end
