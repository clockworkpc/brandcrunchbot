class AllmoxyToolsService # rubocop:disable Metrics/ClassLength
  def sas
    @sas ||= SlackApiService.new
  end

  def allmoxy_services(checked_params:) # rubocop:disable Metrics/MethodLength
    shipping_report = -> { checked_params.key?('shipping_report') }
    orders_report = -> { checked_params.keys.count { |param| param.match?('orders_report') }.positive? }
    orders_report_doors_v5 = -> { checked_params.key?('orders_report_doors_v5') }
    product_tags_report = -> { checked_params.key?('product_tags_report') }
    product_attributes_backup = -> { checked_params.key?('product_attributes_backup') }
    projection_report = -> { checked_params.key?('projection_report') }

    asrs = BrowserService::AllmoxyShippingReportService.new(@browser) if shipping_report.call
    aors = BrowserService::AllmoxyOrdersReportService.new(@browser) if orders_report.call
    aords = BrowserService::AllmoxyOrdersReportDoorService.new(@browser) if orders_report_doors_v5.call
    aprs = BrowserService::AllmoxyProductReportService.new(@browser) if product_tags_report.call
    apas = BrowserService::AllmoxyProductAttributeService.new(@browser) if product_attributes_backup
    aprs2 = BrowserService::AllmoxyProjectionReportService.new(@browser) if projection_report

    {
      asrs:,
      aors:,
      aords:,
      aprs:,
      apas:,
      aprs2:
    }
  end

  def shipping_report(asrs:, spreadsheet_id:, range:)
    Rails.logger.info('Refreshing Shipping Report...'.light_cyan)
    asrs.refresh_shipping_report_input(spreadsheet_id:, range:)
    Rails.logger.info('Shipping Report refreshed :)'.light_cyan)
  end

  def orders_report_doors_v5(aords:)
    doors_spreadsheet_id = Rails.application.credentials[:spreadsheet_id_scheduling_inputs_doors_v5]
    categories = %w[sanded 5pc cnc sanded_panels solidwood]

    categories.each do |category|
      Rails.logger.info("Refreshing Orders Report for Doors ##{category}...".light_cyan)
      aords.refresh_orders_report_input(spreadsheet_id: doors_spreadsheet_id, category:)
      Rails.logger.info("Orders Report for Doors ##{category} refreshed.".light_cyan)
    end
  end

  def orders_report(aors:, spreadsheet_id:, report_key:)
    line = report_key.split('_').last
    method = "refresh_orders_report_input_#{line}"
    Rails.logger.info("Refreshing Orders Report for #{line.capitalize}...".light_cyan)
    aors.send(method, **{ spreadsheet_id: })
    Rails.logger.info("Orders Report for #{line.capitalize} refreshed".light_cyan)
  end

  def product_tags_report(aprs:, phpsessid:)
    spreadsheet_id = Rails.application.credentials[:spreadsheet_id_settings_v5]
    aprs.refresh_product_tags_report(spreadsheet_id:, phpsessid:)
  end

  def product_attributes_backup(apas:)
    Rails.logger.info('Backing up Product Attributes...'.light_cyan)
    product_attribute_ids = apas.all_product_attribute_ids
    apas.back_up_product_attributes(product_attribute_ids:)
    Rails.logger.info('Product Attributes backed up :)'.light_cyan)
  end

  def projection_report(aprs2:, spreadsheet_id:, range:)
    Rails.logger.info('Refreshing Projection Report...'.light_cyan)
    aprs2.refresh_projection_report_input(spreadsheet_id:, range:)
    Rails.logger.info('Projection Report refreshed :)'.light_cyan)
  end

  def refresh_report_from_key(report_key:, # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
                              spreadsheet_id:,
                              range:,
                              allmoxy_services:,
                              sas_parent:,
                              phpsessid: nil)
    asrs = allmoxy_services[:asrs]
    aors = allmoxy_services[:aors]
    aords = allmoxy_services[:aords]
    aprs = allmoxy_services[:aprs]
    apas = allmoxy_services[:apas]
    aprs2 = allmoxy_services[:aprs2]
    title = report_key.titleize

    begin
      case report_key
      when 'shipping_report'
        shipping_report(asrs:, spreadsheet_id:, range:)
      when 'orders_report_doors_v5'
        orders_report_doors_v5(aords:)
      when /orders_report/
        orders_report(aors:, spreadsheet_id:, report_key:)
      when 'product_tags_report'
        product_tags_report(aprs:, phpsessid:)
      when 'product_attributes_backup'
        product_attributes_backup(apas:)
      when 'projection_report'
        projection_report(aprs2:, spreadsheet_id:, range:)
      end

      text_complete = "#{title} has been refreshed."
      sas.post_reply(sas_parent:, text: text_complete)
    rescue StandardError => e
      @browser.close
      Rails.logger.info(e.message)
      text_error = "An error occured when attempting to refresh #{report_key.capitalize}"
      sas.post_reply(sas_parent:, text: text_error)
    end
  end

  def select_spreadsheet_id(checked_params:)
    spreadsheet_id_key = if checked_params.key?('dev')
                           :spreadsheet_id_scheduling_inputs_dev
                         else
                           :spreadsheet_id_scheduling_inputs_prod
                         end
    Rails.application.credentials[spreadsheet_id_key]
  end

  def refresh_reports_slack_parent(checked_params:)
    refreshed_reports = checked_params.keys.reject { |k| k.eql?('dev') }.map(&:titleize)
    text = "The following Scheduling Inputs are to be refreshed: #{refreshed_reports.join(', ')}"
    sas.post_message(text:)
  end

  def refresh_reports_slack_complete(sas_parent:, checked_params:)
    refreshed_reports = checked_params.keys.reject { |k| k.eql?('dev') }.map(&:titleize)
    text = "The following Scheduling Inputs have been refreshed: #{refreshed_reports.join(', ')}"
    sas.post_reply(sas_parent:, text:)
  end

  def refresh_report(allmoxy_report_params)
    checked_params = allmoxy_report_params.select { |_k, v| v == '1' }
    return if checked_params.keys.empty?

    @browser = Utils.watir_browser

    phpsessid = allmoxy_report_params[:phpsessid]
    spreadsheet_id = select_spreadsheet_id(checked_params:)
    allmoxy_services = allmoxy_services(checked_params:)
    sas_parent = refresh_reports_slack_parent(checked_params:)

    checked_params.keys.each do |report_key|
      next if report_key == 'dev'

      range = "#{report_key}!A1:Z"
      refresh_report_from_key(report_key:, spreadsheet_id:, range:, allmoxy_services:, phpsessid:, parent:)
    end

    refresh_reports_slack_complete(sas_parent:, checked_params:)
    @browser.close
  end

  def check_csv_download(csv0:, csv_path:)
    raise StandardError('CSV download failed') if csv0 == csv_path
  rescue StandardError => e
    Logger.log(e)
  end

  def download_completed_orders_report(aors:, start_date:, end_date:)
    statuses = %w[completed shipped]

    csv0 = Utils.latest_csv_in_tmp
    aors.download_orders_report(
      start_date:,
      end_date:,
      statuses:,
      line: 'all'
    )
    csv_path = Utils.latest_csv_in_tmp
    check_csv_download(csv0:, csv_path:)
    csv_path
  end

  def generate_product_order_records(completed_order_params, uploaded_csv = nil) # rubocop:disable Metrics/MethodLength
    Rails.logger.info('Opening a browser in the background')
    @browser = Utils.watir_browser(headless: true)
    aors = BrowserService::AllmoxyOrdersReportService.new(@browser) if uploaded_csv.nil?
    aos = BrowserService::AllmoxyOrderService.new(@browser)

    csv_path = if uploaded_csv
                 uploaded_csv
               else
                 start_date = completed_order_params[:start_date]
                 end_date = completed_order_params[:end_date]
                 download_completed_orders_report(aors:, start_date:, end_date:)
               end

    begin
      aos.generate_order_records(csv_path:)
    rescue StandardError => e
      Rails.logger.info('Something went wrong with generating order records')
      Rails.logger.info(e.message)
      @browser.close
    end
    @browser.close
  end

  def update_finish_price_tracking(completed_order_params)
    spreadsheet_id = Rails.application.credentials[:spreadsheet_id_finish_analysis]
    start_date = completed_order_params[:start_date]
    end_date = completed_order_params[:end_date]
    gsa = GoogleSheetsApi.new
    service = ProductOrderService.new(gsa)
    service.update_finish_price_tracking(spreadsheet_id:, start_date:, end_date:)
  end

  def update_sales_customers(allmoxy_customer_params)
    return unless allmoxy_customer_params.key?('update_sales_customers')

    @browser = Utils.watir_browser(headless: true)
    acs = BrowserService::AllmoxyCustomerService.new(@browser)
    spreadsheet_id = Rails.application.credentials[:spreadsheet_id_allmoxy_customers]
    begin
      if spreadsheet_id
        sas_parent = sas.post_message(text: 'Attempting to update Customer Records...')
        acs.refresh_customers(spreadsheet_id:)
        sas.post_reply(sas_parent:, text: 'Customer Records have been updated.')
      end
    rescue StandardError => e
      Rails.logger.info(e.message)
      text = 'An error occurred when trying to update Customer Records, they have not been updated.'
      sas.post_reply(sas_parent:, text:)
    end
  end
end
