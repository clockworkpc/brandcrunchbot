module SchedulingServices
  class V4Inputs < SchedulingInputs
    def allmoxy_services(checked_params:)
      doors_v5 = -> { checked_params.key?('doors_v5_inputs') }
      drawers_v5 = -> { checked_params.key?('drawers_v5_inputs') }
      specialty_v5 = -> { checked_params.key?('specialty_v5_inputs') }
      finish_v5 = -> { checked_params.key?('finish_v5_inputs') }

      door_order_service = BrowserService::AllmoxyOrdersReportDoorService.new(@browser) if doors_v5.call
      drawer_order_service = BrowserService::AllmoxyOrdersReportDrawerService.new(@browser) if drawers_v5.call
      specialty_order_service = BrowserService::AllmoxyOrdersReportSpecialtyService.new(@browser) if specialty_v5.call
      finish_order_service = BrowserService::AllmoxyOrdersReportFinishService.new(@browser) if finish_v5.call

      {
        door_order_service:,
        drawer_order_service:,
        specialty_order_service:,
        finish_order_service:
      }
    end

    def update_shipping_input(sas_parent:)
      spreadsheet_id = Rails.application.credentials[:spreadsheet_id_scheduling_inputs_prod]
      sas.post_reply(sas_parent:, text: 'Refreshing the Shipping Report')
      service = BrowserService::AllmoxyShippingReportService.new(@browser)
      service.refresh_shipping_report_input(spreadsheet_id:)
      sas.post_reply(sas_parent:, text: 'Shipping Report refreshed')
    end

    def update_projection_input(sas_parent:)
      spreadsheet_id = Rails.application.credentials[:spreadsheet_id_scheduling_inputs_prod]
      sas.post_reply(sas_parent:, text: 'Refreshing the Projection Report')
      service = BrowserService::AllmoxyProjectionReportService.new(@browser)
      service.refresh_projection_report_input(spreadsheet_id:)
      sas.post_reply(sas_parent:, text: 'Projection Report refreshed')
    end

    def door_orders(door_order_service:, sas_parent:)
      return unless door_order_service

      key = :spreadsheet_id_scheduling_inputs_doors_v5
      spreadsheet_id = Rails.application.credentials[key]
      categories = %w[sanded 5pc cnc sanded_panels solidwood]

      categories.each do |category|
        text_start = "Refreshing Orders Report for Doors ##{category}..."
        Rails.logger.info(text_start.light_cyan)
        sas.post_reply(sas_parent:, text: text_start)

        door_order_service.call(spreadsheet_id:, category:)
        text_complete = "Orders Report for Doors ##{category} refreshed."
        Rails.logger.info(text_complete.light_cyan)
        sas.post_reply(sas_parent:, text: text_complete)
      end
    end

    def orders(service:, sas_parent:)
      return unless service

      line = service.class.to_s.scan(/Drawer|Specialty|Finish/).first.downcase
      key = :spreadsheet_id_scheduling_inputs_prod
      spreadsheet_id = Rails.application.credentials[key]

      text_start = "Refreshing Orders Report for #{line.capitalize}..."
      Rails.logger.info(text_start.light_cyan)
      sas.post_reply(sas_parent:, text: text_start)

      service.call(spreadsheet_id:)
      text_complete = "Orders Report for #{line.capitalize} refreshed"
      Rails.logger.info(text_complete.light_cyan)
      sas.post_reply(sas_parent:, text: text_complete)
    end

    def call(v4_input_params)
      checked_params = checked_params(input_params: v4_input_params)
      sas_parent = refresh_reports_slack_parent(checked_params:)

      return if checked_params.empty?

      @browser = Utils.watir_browser

      begin
        allmoxy_services = allmoxy_services(checked_params:)
        door_order_service = allmoxy_services[:door_order_service]
        drawer_order_service = allmoxy_services[:drawer_order_service]
        specialty_order_service = allmoxy_services[:specialty_order_service]
        finish_order_service = allmoxy_services[:finish_order_service]

        update_shipping_input(sas_parent:)
        update_projection_input(sas_parent:) if specialty_order_service

        door_orders(door_order_service:, sas_parent:)
        orders(service: drawer_order_service, sas_parent:)
        orders(service: specialty_order_service, sas_parent:)
        orders(service: finish_order_service, sas_parent:)
        refresh_reports_slack_complete(sas_parent:, checked_params:)
      rescue StandardError => e
        Rails.logger.info(e)
      ensure
        Rails.logger.info('Browser closed')
        @browser.close
      end
    end
  end
end
