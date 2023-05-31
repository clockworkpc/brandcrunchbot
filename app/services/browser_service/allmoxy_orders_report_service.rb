class BrowserService
  class AllmoxyOrdersReportService < AllmoxyService
    def upload_orders_report(spreadsheet_id:, range:, csv_path:)
      gsa = GoogleSheetsApi.new
      Rails.logger.info("Clearing values from spreadsheet: #{spreadsheet_id}, range: #{range}".light_cyan)
      gsa.clear_values(spreadsheet_id:, range:)
      Rails.logger.info("Updating values in spreadsheet: #{spreadsheet_id}, range: #{range}".light_cyan)
      res = gsa.update_values(spreadsheet_id:, range:, csv_path:)
      Rails.logger.info('Values updated!'.light_cyan)
      res
    end

    def orders_report_post(start_date:, end_date:, statuses:, line:, category: nil) # rubocop:disable Metrics/MethodLength
      if category
        tags_any_product = ALLMOXY_CONSTANTS['orders_report'][line][category]['tags_any_product']
        tags_none_product = ALLMOXY_CONSTANTS['orders_report'][line][category]['tags_none_product']
      elsif line.eql?('all')
        tags_any_order = nil
        tags_none_order = nil
      else
        tags_any_order = ALLMOXY_CONSTANTS['orders_report'][line]['tags_any_order']
        tags_none_order = ALLMOXY_CONSTANTS['orders_report'][line]['tags_none_order']
      end

      type = category ? 'PRODUCTS' : 'ORDERS'
      tags = tags_any_product || tags_any_order

      info = if tags.nil?
               'Requesting an Orders Report for all orders'.light_cyan
             else
               "Requesting an Orders Report for any #{type} tagged ##{tags.split.join(', #')}".light_cyan
             end

      Rails.logger.info(info)

      @aas.orders_report_post(start_date:, end_date:, statuses:,
                              tags_any_order:,
                              tags_none_order:,
                              tags_any_product:,
                              tags_none_product:)
    end

    def orders_report_csv_get(category: nil, line: nil)
      type = category || line
      Rails.logger.info("Downloading an Orders Report for #{type}".light_cyan)
      @aas.orders_report_csv(line: type)
    end

    def download_orders_report(start_date:, end_date:, statuses:, line:, category: nil)
      csv0 = Utils.latest_csv_in_tmp
      orders_report_post(start_date:, end_date:, statuses:, line:, category:)
      orders_report_csv_get(line:, category:)
      csv1 = Utils.latest_csv_in_tmp
      Rails.logger.info("CSV0: #{csv0}")
      Rails.logger.info("CSV1: #{csv0}")
      return if csv0 == csv1

      csv1
    end

    # rubocop:disable Metrics/ParameterLists
    def refresh_orders_report_input(spreadsheet_id:,
                                    range: nil,
                                    start_date: nil,
                                    end_date: nil,
                                    statuses: nil,
                                    category: nil,
                                    line: nil)
      start_date ||= Utils.first_day_two_months_ago
      end_date ||= Utils.last_day_two_months_hence
      statuses ||= ['verified', 'in progress']
      range ||= "#{category || line}!A1:Z"

      begin
        csv_path = download_orders_report(start_date:, end_date:, statuses:, category:, line:)
        upload_orders_report(spreadsheet_id:, range:, csv_path:)
      rescue StandardError => e
        @browser.close
        Rails.logger.info(e.message.red)
      end
    end
    # rubocop:enable Metrics/ParameterLists

    def refresh_ancillary_inputs(sas_parent:, shipping_report: false, projection_report: false)
      return unless shipping_report || projection_report

      key = :spreadsheet_id_scheduling_inputs_prod
      spreadsheet_id = Rails.application.credentials[key]

      sr = 'Shipping Report' if shipping_report
      pr = 'Projection Report' if projection_report
      text = "Refreshing ancillary inputs: #{[sr, pr].join(', ')}"
      sas = SlackApiService.new
      sas.post_reply(sas_parent:, text:)

      if shipping_report
        sr_service = BrowserService::AllmoxyShippingReportService.new(@browser)
        sr_service.refresh_shipping_report_input(spreadsheet_id:)
      end

      return unless projection_report

      pr_service = BrowserService::AllmoxyProjectionReportService.new(@browser)
      pr_service.refresh_projection_report_input(spreadsheet_id:)
    end
  end
end
