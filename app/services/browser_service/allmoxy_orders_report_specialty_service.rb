class BrowserService
  class AllmoxyOrdersReportSpecialtyService < AllmoxyOrdersReportService
    def gsa
      @gsa ||= GoogleSheetsApi.new
    end

    def read_archive_orders(spreadsheet_id:, range:, shipping_report: true, projection_report: true)
      range ||= 'specialty_hours_hidden!A1:B'
      res = gsa.get_spreadsheet_values(spreadsheet_id:, range:)
      body = res.values[1..-1]
      body.map do |row|
        {
          order: row[0].to_i,
          product_name: row[1]
        }
      end
    end

    def diff_orders(archived_orders:, csv:)
      csv_orders = csv.map do |row|
        { order: row[:order], product_name: row[:product_name] }
      end
      diff = csv_orders - archived_orders
      diff.map { |row| [row[:order], row[:product_name]] }
    end

    # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
    def update_orders_archive(spreadsheet_id: nil,
                              range: nil,
                              start_date: nil,
                              end_date: nil,
                              statuses: nil,
                              category: nil,
                              line: nil)
      spreadsheet_id ||= Rails.application.credentials[:spreadsheet_id_specialty_v5]
      start_date ||= Utils.first_day_two_months_ago
      end_date ||= Utils.last_day_two_months_hence
      statuses ||= ['verified']
      range ||= 'specialty_hours_hidden!A2:B'
      line ||= 'specialty'

      # TODO: Diff between combined specialty order tags and product tags
      begin
        archived_orders = read_archive_orders(spreadsheet_id:, range:)
        csv_path = download_orders_report(start_date:, end_date:, statuses:, category:, line:)
        csv = CSV.table(csv_path, headers: true)
        values = diff_orders(archived_orders:, csv:)
        gsa.append_spreadsheet_value(spreadsheet_id:, range:, values:)
      rescue StandardError => e
        @browser.close
        Rails.logger.info(e.message.red)
      end
    end
    # rubocop:enable Metrics/ParameterLists, Metrics/MethodLength

    def call(spreadsheet_id:)
      order_tags_range = 'specialty_order_tags!A1:O'
      product_tags_range = 'specialty_product_tags!A1:O'

      line = 'specialty'
      category = 'specialty'
      # Orders Report by Order Tag
      refresh_orders_report_input(spreadsheet_id:, line:, range: order_tags_range)
      # Orders Report by Product Tag
      refresh_orders_report_input(spreadsheet_id:, line:, category:, range: product_tags_range)
      # Append verified orders to archive

      update_orders_archive(
        range: 'specialty_hours_hidden!A1:B',
        statuses: ['verified']
      )
    end
  end
end
