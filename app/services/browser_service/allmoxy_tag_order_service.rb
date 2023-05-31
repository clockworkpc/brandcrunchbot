class BrowserService
  class AllmoxyTagOrderService < AllmoxyOrdersReportService
    NUMBER_TAGS = '01'.upto('31').to_a.freeze
    ORDERS_REPORT_HEADERS = [['Tag #', 'Order #', 'Company #', 'Company Name',
                              'Order Name', 'Total', 'Number of Pieces',
                              'Ordered Date', 'Ship Date', 'Status',
                              'Product #', 'Product Name', 'Qty', 'Line Subtotal']].freeze

    def orders_report_post(start_date:, end_date:, statuses:, tag_number:)
      tags_any_order = ALLMOXY_CONSTANTS['orders_report']['number_tags'][tag_number]['tags_any_order']
      tags_none_order = ALLMOXY_CONSTANTS['orders_report']['number_tags'][tag_number]['tags_none_order']

      @aas.orders_report_post(start_date:, end_date:, statuses:,
                              tags_any_order:,
                              tags_none_order:)
    end

    def empty_report?(res:)
      doc = Nokogiri::HTML(res.body)
      first_entry = doc.xpath('//table[@class="moxtable sortable"]/tbody/tr').first
      first_entry.text.match?('No results found')
    end

    def download_orders_report(start_date:, end_date:, statuses:, tag_number:)
      csv0 = Utils.latest_csv_in_tmp
      res = orders_report_post(start_date:, end_date:, statuses:, tag_number:)
      return if empty_report?(res:)

      orders_report_csv_get(line: tag_number)
      csv1 = Utils.latest_csv_in_tmp
      Rails.logger.info("CSV0: #{csv0}")
      Rails.logger.info("CSV1: #{csv0}")
      return if csv0 == csv1

      csv1
    end

    def append_orders_report(spreadsheet_id:, csv_path:, tag:)
      return unless csv_path

      range = 'number_tags!A1:N'
      csv = CSV.read(csv_path)[1..-1]
      values = csv.map { |row| row.unshift(tag) }
      gsa.append_spreadsheet_value(spreadsheet_id:, range:, values:)
    end

    def refresh_tag_report_input(spreadsheet_id:, tag:)
      start_date ||= Utils.first_day_two_months_ago
      end_date ||= Utils.last_day_two_months_hence
      statuses ||= ['verified', 'in progress']
      tag_number = ['tag', tag].join('_')
      begin
        csv_path = download_orders_report(start_date:, end_date:, statuses:, tag_number:)
        Rails.logger.info("No orders for Tag ##{tag}".yellow) if csv_path.nil?
        append_orders_report(spreadsheet_id:, csv_path:, tag:)
      rescue StandardError => e
        @browser.close
        Rails.logger.info(e.message.red)
      end
    end

    def set_up_sheet(spreadsheet_id:)
      Rails.logger.info('Clearing the values from number_tags!A1:Z'.green)
      gsa.clear_values(spreadsheet_id:, range: 'number_tags!A1:Z')
      Rails.logger.info('Inserting headers to number_tags sheet')
      gsa.append_spreadsheet_value(spreadsheet_id:,
                                   range: 'number_tags!A1:N',
                                   values: ORDERS_REPORT_HEADERS)
    end

    def call(spreadsheet_id: nil)
      key = :spreadsheet_id_production_scheduling
      spreadsheet_id ||= Rails.application.credentials[key]
      set_up_sheet(spreadsheet_id:)
      NUMBER_TAGS.each { |tag| refresh_tag_report_input(spreadsheet_id:, tag:) }
    end
  end
end
