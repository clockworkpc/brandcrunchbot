require 'uri'
require 'net/http'

class BrowserService
  class AllmoxyService < BrowserService
    attr_reader :aas

    BASE_URL = 'https://panhandledooranddrawer.allmoxy.com'.freeze
    HOME_PAGE = [BASE_URL, 'home', 'time_card'].join('/').freeze
    LOGIN_PAGE = [BASE_URL, 'public', 'login/'].join('/').freeze
    ORDERS_REPORT_URL = [BASE_URL, 'reports', 'orders'].join('/').freeze
    ORDERS_REPORT_CSV_URL = [BASE_URL, 'reports', 'orders', 'export'].join('/').freeze
    SHIPPING_REPORT_URL = [BASE_URL, 'reports', 'delivery/'].join('/').freeze
    SHIPPING_REPORT_CSV_URL = [BASE_URL, 'reports', 'delivery', 'export'].join('/').freeze
    DOWNLOADS_FOLDER = File.expand_path('~/Downloads/')
    INPUTS_SHEET_ID = '1o79rNF6v7ZXBhxDyzL2EsxG4rE8cUAf0PKa2jaMdqio'.freeze
    INPUTS_SHEET_DEV_ID = '1n_GqOd2YkXv-gvTut0og_eeqeqj5wmuSgB9JSheX5GU'.freeze
    ALLMOXY_CONSTANTS = JSON.parse(File.read('app/assets/config/allmoxy_constants.json'))

    def initialize(browser = nil, browser_close = nil)
      super(browser) if browser
      phpsessid = retrieve_phpsessid(browser)
      @browser.close if browser_close

      @aas = AllmoxyApiService.new(phpsessid)
      @utils = Utils.new
    end

    def retrieve_phpsessid_via_browser(browser)
      logged_in = browser.url.match?(BASE_URL) && !browser.url.eql?(LOGIN_PAGE)
      Rails.logger.info("Logged in? #{logged_in}".yellow)
      sign_in unless logged_in
      @browser.cookies.to_a.find { |cookie| cookie[:name].eql?('PHPSESSID') }[:value]
    end

    def add_request_headers(request, phpsessid) # rubocop:disable Metrics/MethodLength
      request['Accept'] =
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8'
      request['Accept-Language'] = 'en-US,en;q=0.9'
      request['Cache-Control'] = 'max-age=0'
      request['Connection'] = 'keep-alive'
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request['Cookie'] = "PHPSESSID=#{phpsessid}"
      request['Origin'] = 'https://panhandledooranddrawer.allmoxy.com'
      request['Referer'] = 'https://panhandledooranddrawer.allmoxy.com/public/login/'
      request['Sec-Fetch-Dest'] = 'document'
      request['Sec-Fetch-Mode'] = 'navigate'
      request['Sec-Fetch-Site'] = 'same-origin'
      request['Sec-Fetch-User'] = '?1'
      request['Sec-GPC'] = '1'
      request['Upgrade-Insecure-Requests'] = '1'
      request['User-Agent'] =
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36'
      request['sec-ch-ua'] = '"Brave";v="113", "Chromium";v="113", "Not-A.Brand";v="24"'
      request['sec-ch-ua-mobile'] = '?0'
      request['sec-ch-ua-platform'] = '"Linux"'
      request
    end

    def login_post_response(phpsessid)
      url = URI('https://panhandledooranddrawer.allmoxy.com/public/login/')
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(url)
      add_request_headers(request, phpsessid)
      username = Rails.application.credentials[:allmoxy_username]
      password = Rails.application.credentials[:allmoxy_password]
      request.body = "username=#{username}&password=#{password}"
      https.request(request)
    end

    def get_response(response, phpsessid)
      url = URI(response['location'])
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Get.new(url)
      add_request_headers(request, phpsessid)
      https.request(request)
    end

    def retrieve_phpsessid_via_http_call
      string_length = 26
      phpsessid = rand(36**string_length).to_s(36)
      puts Rainbow("phpsessid from AllmoxyService = #{phpsessid}").red
      login_post_response = login_post_response(phpsessid)

      if login_post_response.code.to_i == 302
        home_get_response = get_response(login_post_response, phpsessid)

        timecard_get_response = get_response(home_get_response, phpsessid) if home_get_response.code.to_i == 302
      end

      phpsessid if timecard_get_response.code.to_i == 200
    end

    def retrieve_phpsessid(browser)
      if browser
        retrieve_phpsessid_via_browser(browser)
      else
        retrieve_phpsessid_via_http_call
      end
    end

    def gsa
      @gsa ||= GoogleSheetsApi.new
    end

    def spreadsheet_dates(spreadsheet_id:, date_column:, sheet_name:)
      date_range = "#{sheet_name}!#{date_column}1:#{date_column}"
      gsa.get_spreadsheet_values(spreadsheet_id:, range: date_range)
    end

    def values_for_start_date(spreadsheet_id:, range:, start_date:, date_column: 'A')
      sheet_name = range.split('!').first
      date_res = spreadsheet_dates(spreadsheet_id:, date_column:, sheet_name:)
      dates = date_res.values.flatten

      day = start_date.iso8601
      rows_day = dates.select { |cell| cell.eql?(day) }
      row_day_count = rows_day.count
      return if row_day_count.zero?

      first_column = range.split('!').last.split(':').first.scan(/[a-zA-Z]+/).first
      last_column = range.split('!').last.split(':').last.scan(/[a-zA-Z]+/).first

      row_count = dates.count
      day_row_first = "#{first_column}#{(row_count + 1) - row_day_count}"
      day_row_last = "#{last_column}#{row_count}"

      "#{sheet_name}!#{day_row_first}:#{day_row_last}"
    end

    def values_for_today(spreadsheet_id:, range:, date_column: 'A')
      start_date = Time.zone.today.iso8601
      values_for_start_date(spreadsheet_id:, range:, start_date:, date_column:)
    end

    def clear_values_for_start_date(spreadsheet_id:, range:, start_date:, date_column: 'A')
      date_range = values_for_start_date(spreadsheet_id:, range:, start_date:, date_column:)
      if date_range.nil?
        Rails.logger.info('No values for date range'.light_green)
        return
      end

      Rails.logger.info("Date Range: #{date_range}".green)
      gsa.clear_values(spreadsheet_id:, range: date_range)
    end

    def clear_values_for_today(spreadsheet_id:, range:, date_column: 'A')
      start_date = Time.zone.today.iso8601
      clear_values_for_start_date(spreadsheet_id:, range:, start_date:, date_column:)
    end

    # rubocop:disable Metrics/ParameterLists
    def clear_values_for_this_week(spreadsheet_id:, sheet_name:, first_column: 'A', last_column: 'Z',
                                   date_column_int: 0, last_integer: -1)
      start_date = Utils.start_dates_to_date[last_integer]
      range = "#{sheet_name}!#{first_column}1:#{last_column}"
      res = gsa.get_spreadsheet_values(spreadsheet_id:, range:)
      this_week_values = res.values.select { |row| row[date_column_int].eql?(start_date.to_s) }
      del_row_start = (res.values.count + 1) - this_week_values.count
      delete_range = "#{sheet_name}!#{first_column}#{del_row_start}:#{last_column}"
      clear_values_for_start_date(spreadsheet_id:, range: delete_range, start_date:)
    end
    # rubocop:enable Metrics/ParameterLists

    def missing_start_dates(start_dates:, spreadsheet_id:, sheet_name:, start_date_column: 'A')
      range = "#{sheet_name}!#{start_date_column}2:#{start_date_column}"
      res = gsa.get_spreadsheet_values(spreadsheet_id:, range:)
      recorded_start_date_strings = res.values.nil? ? [] : res.values.flatten
      recorded_start_dates = recorded_start_date_strings.uniq.map { |d| Date.parse(d) }
      start_dates - recorded_start_dates
    end
  end
end
