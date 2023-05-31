class BrowserService
  class AllmoxyOrderHistoryService < AllmoxyService
    def status_strings
      [
        'Shipped',
        'Completed',
        'In Progress',
        'Verified',
        'Ordered',
        'Bid'
      ]
    end

    def extract_status_details(tr:)
      pst_notation = '%m/%d/%y %I:%M %p%z'
      datetime_regex = %r{\d+\/\d+\/\d+ \d+:\d+ [AP]M}
      status_regex = /#{status_strings.join('|')}/
      split = tr.text.split("\n").compact_blank.map(&:strip)

      allmoxy_user = split.first
      status = tr.text.scan(status_regex).first
      datetime_str = [tr.text.scan(datetime_regex).first, '-7'].join

      begin
        datetime = DateTime.strptime(datetime_str, pst_notation).in_time_zone('America/Los_Angeles')
      rescue Date::Error => e
        Rails.logger.info e.message
        datetime = nil
      end

      { allmoxy_user:, status:, datetime: }
    end

    def download_order_history(order_number:)
      Rails.logger.info("Downloading history of #{order_number}".light_green)
      res = @aas.order_history_get(order_number:)
      return unless res.body

      doc = Nokogiri::HTML(res.body)
      tbody = doc.xpath('//tbody').first
      return unless tbody

      trs = tbody.xpath('./tr')
      return if trs.empty?

      trs.map { |tr| extract_status_details(tr:) }
    end

    def completed_at(order_number:)
      history = download_order_history(order_number:)
      completed = history.find { |hsh| hsh[:status].eql?('Completed') }
      return if completed.nil?

      date = completed[:datetime].iso8601[0...10]
      { order_number:, date: }
    end

    def save_order_status_history(order_number:, status_history_hsh_ary:)
      order = Order.find_by(order_number:)
      return unless order

      completed_record = status_history_hsh_ary.find { |hsh| hsh[:status].eql?('Completed') }
      order.completed_at = completed_record[:datetime].to_date if completed_record

      status_history = status_history_hsh_ary.to_json
      order.status_history = status_history
      order.save!
    end

    def update_status_history(order_number:)
      status_history_hsh_ary = download_order_history(order_number:)
      return unless status_history_hsh_ary

      Rails.logger.info("Updating Status History for #{order_number}")
      save_order_status_history(order_number:, status_history_hsh_ary:)
    end

    def update_status_histories(order_numbers:)
      order_numbers.each { |order_number| update_status_history(order_number:) }
    end

    def update_completion_dates_in_finish_analysis
      key = :spreadsheet_id_finish_analysis
      range = 'orders_completed_date!G2:G'
      spreadsheet_id = Rails.application.credentials[key]
      res = gsa.get_spreadsheet_values(spreadsheet_id:, range:)
      return if res.values.nil?

      order_numbers = res.values.flatten
      records = order_numbers.map do |order_number|
        Rails.logger.info("Order: #{order_number}")
        completed_at(order_number:)
      end
      update_range = 'retrieved_completed_dates!A1:B'
      values = records.map { |hsh| [hsh[:order_number], hsh[:date]] }
      gsa.append_spreadsheet_value(spreadsheet_id:, range: update_range, values:)
    end

    def add_line_item(line_item_hsh:, hsh:)
      key = hsh[:status].downcase.split.join
      key_user = [key, 'user'].join('_')
      key_dt = [key, 'dt'].join('_')
      key_date = [key, 'date'].join('_')

      line_item_hsh[key_user] = hsh[:allmoxy_user]
      line_item_hsh[key_dt] = hsh[:datetime]
      line_item_hsh[key_date] = hsh[:datetime].iso8601[0...10]
    end

    def new_line_item_hash(order_number:) # rubocop:disable Metrics/MethodLength
      {
        order_number:,
        shipped_user: nil,
        shipped_dt: nil,
        shipped_date: nil,
        completed_user: nil,
        completed_dt: nil,
        completed_date: nil,
        inprogress_user: nil,
        inprogress_dt: nil,
        inprogress_date: nil,
        verified_user: nil,
        verified_dt: nil,
        verified_date: nil,
        ordered_user: nil,
        ordered_dt: nil,
        ordered_date: nil,
        bid_user: nil,
        bid_dt: nil,
        bid_date: nil
      }.transform_keys(&:to_s)
    end

    def sheet_line_item_hash(order_number:, hsh_ary:)
      line_item_hsh = new_line_item_hash(order_number:)

      records = hsh_ary.uniq { |hsh| hsh[:status] }
                       .reject { |hsh| hsh[:status].nil? }

      records.each do |hsh|
        missing_record = hsh.keys.count { |key| hsh[key].nil? }.positive?
        next if missing_record

        add_line_item(line_item_hsh:, hsh:)
      end

      line_item_hsh
    end

    def order_history_hash(order_number:)
      hsh_ary = download_order_history(order_number:)
      sheet_line_item_hash(order_number:, hsh_ary:)
    end

    def order_history_hash_array(order_numbers:)
      order_numbers.map { |order_number| order_history_hash(order_number:) }
    end

    def recorded_orders
      key = :spreadsheet_id_order_history
      spreadsheet_id = Rails.application.credentials[key]
      range = "#{Date.current.year}!A2:A"
      res = gsa.get_spreadsheet_values(spreadsheet_id:, range:)
      return [] if res.values.nil?

      res.values.map { |row| row.first.to_i }
    end

    def new_order_numbers(start_date: nil, end_date: nil)
      service = BrowserService::AllmoxyOrdersReportService.new(@browser)
      start_date ||= Utils.first_day_two_months_ago
      end_date ||= Utils.last_day_two_months_hence
      statuses = %w[completed shipped]
      line = 'all'
      csv_path = service.download_orders_report(start_date:, end_date:, statuses:, line:)
      csv = CSV.table(csv_path, headers: true)
      csv_order_numbers = csv.pluck(:order).uniq
      Rails.logger.info("CSV Orders: #{csv_order_numbers.count}".yellow)
      spreadsheet_order_numbers = recorded_orders
      Rails.logger.info("Spreadsheet Orders: #{spreadsheet_order_numbers.count}".yellow)
      csv_order_numbers - spreadsheet_order_numbers
    end

    def order_report_hash_array(start_date:, end_date:)
      service = BrowserService::AllmoxyOrdersReportService.new(@browser)
      statuses = %w[completed shipped]
      line = 'all'
      csv_path = service.download_orders_report(start_date:, end_date:, statuses:, line:)
      csv = CSV.table(csv_path, headers: true)
      csv.map(&:to_h)
    end

    def refresh_order_report_for_the_year
      service = BrowserService::AllmoxyOrdersReportService.new(@browser)
      statuses = %w[completed shipped]
      line = 'all'
      start_date = "#{Date.current.year}-01-01"
      end_date = "#{Date.current.year}-12-31"
      csv_path = service.download_orders_report(start_date:, end_date:, statuses:, line:)
      spreadsheet_id = Rails.application.credentials[:spreadsheet_id_order_history]
      range = 'order_report!A1:Z'
      gsa.clear_values(spreadsheet_id:, range:)
      gsa.update_values(spreadsheet_id:, range:, csv_path:)
    end

    def min_ship_date(allmoxy_orders:)
      allmoxy_orders.map { |hsh| Date.parse(hsh[:ship_date]) }
                    .uniq.sort.min
    end

    def add_order_sync_record(allmoxy_orders:)
      earliest_ship_date = min_ship_date(allmoxy_orders:)
      OrderSyncRecord.create(earliest_ship_date:)
    end

    def parsed_gsheet_row_value(header:, raw_value:)
      return if raw_value.blank?

      case header.to_s
      when /dt/
        DateTime.parse(raw_value)
      when /date/
        Date.parse(raw_value)
      else
        raw_value
      end
    end

    def google_sheet_orders(start_date:, spreadsheet_id:, range:)
      res = gsa.get_spreadsheet_values(spreadsheet_id:, range:)
      headers = res.values.first.map(&:to_sym)
      hsh_ary = []
      res.values[1..-1].each do |row|
        hsh = {}
        headers.each_with_index do |header, index|
          raw_value = row[index]
          value = parsed_gsheet_row_value(header:, raw_value:)
          hsh[header] = value
        end
        hsh_ary << hsh
      end
      hsh_ary
    end

    def filter_newly_shipped_orders(allmoxy_orders_shipped:,
                                    gsheet_orders_shipped:)
      ary = []
      allmoxy_orders_shipped.each do |order|
        final_record_in_allmoxy_and_gsheet = gsheet_orders_shipped.find { |go| go[:order].to_i == order[:order].to_i }
        next if final_record_in_allmoxy_and_gsheet

        ship_date_last_year = Date.parse(order[:ship_date]).year < Date.current.year
        next if ship_date_last_year

        ary << order[:order]
      end

      ary.uniq
    end

    def filter_completed_orders(allmoxy_orders_completed:, gsheet_orders_shipped:)
      ary = allmoxy_orders_completed.pluck(:order).uniq
      # Filter out any orders that are "Completed" but have a ship date
      ary - gsheet_orders_shipped.pluck(:order).map(&:to_i)
    end

    def triage_orders(allmoxy_orders_shipped:, allmoxy_orders_completed:, gsheet_orders_shipped:)
      shipped_orders_to_download = filter_newly_shipped_orders(allmoxy_orders_shipped:,
                                                               gsheet_orders_shipped:)
      completed_orders_to_download = filter_completed_orders(allmoxy_orders_completed:, gsheet_orders_shipped:)

      Rails.logger.info("Shipped Orders to download: #{shipped_orders_to_download.uniq}".light_red)
      Rails.logger.info("Completed Orders to download: #{completed_orders_to_download.uniq}".light_red)

      (shipped_orders_to_download + completed_orders_to_download).uniq
    end

    def download_order_histories(order_numbers:)
      order_numbers.map { |order_number| order_history_hash(order_number:) }
    end

    def spreadsheet_headers
      Order.new.attributes.keys
           .reject { |k| k.match?(/id|created_at|updated_at/) }
    end

    def refresh_completed_orders(spreadsheet_id:, downloaded_order_histories:)
      range = "completed_#{Date.current.year}"
      headers = spreadsheet_headers
      hsh_ary = downloaded_order_histories.select { |hsh| hsh['shipped_date'].nil? }
      gsa.clear_values(spreadsheet_id:, range:)
      gsa.update_values_from_simple_hash_array(spreadsheet_id:, range:, headers:, hsh_ary:)
    end

    def append_shipped_orders(spreadsheet_id:, downloaded_order_histories:, gsheet_orders_shipped:)
      range = "shipped_#{Date.current.year}"
      hsh_ary = downloaded_order_histories.reject { |hsh| hsh['shipped_date'].nil? }
      values = hsh_ary.map(&:values)
      gsa.append_spreadsheet_value(spreadsheet_id:, range:, values:)
    end

    def start_date_for_this_year
      stringify = ->(x) { x.iso8601[0...10] }
      a = Date.parse(Utils.first_day_two_months_ago)
      b = Date.parse("#{Date.current.year}-01-01")

      a > b ? stringify.call(a) : stringify.call(b)
    end

    def end_date_for_this_year
      stringify = ->(x) { x.iso8601[0...10] }
      a = Date.parse(Utils.last_day_two_months_hence)
      b = Date.parse("#{Date.current.year}-12-31")

      a < b ? stringify.call(a) : stringify.call(b)
    end

    def allmoxy_and_gsheet_orders(spreadsheet_id:)
      refresh_order_report_for_the_year

      start_date = start_date_for_this_year
      end_date = end_date_for_this_year

      allmoxy_orders = order_report_hash_array(start_date:, end_date:)
      add_order_sync_record(allmoxy_orders:)

      allmoxy_orders_shipped = allmoxy_orders.select { |hsh| hsh[:status].eql?('shipped') }
      allmoxy_orders_completed = allmoxy_orders.select { |hsh| hsh[:status].eql?('completed') }

      range = "all_#{Date.current.year}!A1:Z"
      gsheet_orders = google_sheet_orders(start_date:, spreadsheet_id:, range:)
      gsheet_orders_shipped = gsheet_orders.select { |hsh| hsh[:shipped_date] }

      [allmoxy_orders_shipped, allmoxy_orders_completed, gsheet_orders_shipped]
    end

    def save_order_history(order_history:)
      order_number = order_history[:order_number]
      order = Order.find_by(order_number:) || Order.new
      order.update(order_history)
      order.save!
    end

    def update_order_history_sheet(spreadsheet_id: nil, order_numbers: nil)
      spreadsheet_id ||= Rails.application.credentials[:spreadsheet_id_order_history]

      if order_numbers.nil?
        allmoxy_orders_shipped,
          allmoxy_orders_completed,
          gsheet_orders_shipped = allmoxy_and_gsheet_orders(spreadsheet_id:)
      end

      triaged_orders = order_numbers || triage_orders(allmoxy_orders_shipped:,
                                                      allmoxy_orders_completed:,
                                                      gsheet_orders_shipped:)

      downloaded_order_histories = download_order_histories(order_numbers: triaged_orders)
      downloaded_order_histories.each { |order_history| save_order_history(order_history:) }

      refresh_completed_orders(spreadsheet_id:, downloaded_order_histories:)
      append_shipped_orders(spreadsheet_id:, downloaded_order_histories:, gsheet_orders_shipped:)
    end
  end

  def production_schedule_orders
    ps_order_numbers = lambda do |line|
      key = "spreadsheet_id_#{line}_production_schedule".to_sym
      spreadsheet_id = Rails.application.credentials[key]
      range = "#{line}_dashboard!D3:D"
      res = gsa.get_spreadsheet_values(spreadsheet_id:, range:)
      res.values.reject(&:empty?).map(&:first).uniq.sort
    end

    doors_orders = ps_order_numbers.call('doors')
    boxes_orders = ps_order_numbers.call('boxes')

    (doors_orders + boxes_orders).uniq.sort
  end

  def refresh_production_schedule_orders(spreadsheet_id:, downloaded_order_histories:)
    range = 'production_schedule'
    headers = spreadsheet_headers
    hsh_ary = downloaded_order_histories.select { |hsh| hsh['shipped_date'].nil? }
    gsa.clear_values(spreadsheet_id:, range:)
    gsa.update_values_from_simple_hash_array(spreadsheet_id:, range:, headers:, hsh_ary:)
  end

  def update_verified_order_history_sheet(spreadsheet_id: nil, order_numbers: nil)
    spreadsheet_id ||= Rails.application.credentials[:spreadsheet_id_order_history]

    order_numbers ||= production_schedule_orders
    downloaded_order_histories = download_order_histories(order_numbers:)
    refresh_production_schedule_orders(spreadsheet_id:, downloaded_order_histories:)
  end
end
