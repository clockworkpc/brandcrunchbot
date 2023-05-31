module SchedulingServices
  class AncillaryInputs < SchedulingInputs
    def allmoxy_services(checked_params:)
      shipping_report = -> { checked_params.key?('shipping_report') }
      projection_report = -> { checked_params.key?('projection_report') }
      tags_report = -> { checked_params.key?('tags_report') }

      asrs = BrowserService::AllmoxyShippingReportService.new(@browser) if shipping_report.call
      aprs = BrowserService::AllmoxyProjectionReportService.new(@browser) if projection_report.call
      atos = BrowserService::AllmoxyTagOrderService.new(@browser) if tags_report.call

      {
        asrs:,
        aprs:,
        atos:
      }
    end

    def shipping_report(asrs:)
      return unless asrs

      key = :spreadsheet_id_scheduling_inputs_prod
      spreadsheet_id = Rails.application.credentials[key]
      range = 'shipping_report!A1:K'
      Rails.logger.info('Refreshing Shipping Report...'.light_cyan)
      asrs.refresh_shipping_report_input(spreadsheet_id:, range:)
      Rails.logger.info('Shipping Report refreshed :)'.light_cyan)
    end

    def projection_report(aprs:)
      return unless aprs

      key = :spreadsheet_id_scheduling_inputs_prod
      spreadsheet_id = Rails.application.credentials[key]
      range = 'projection_report!A1:M'
      Rails.logger.info('Refreshing Projection Report...'.light_cyan)
      aprs.refresh_projection_report_input(spreadsheet_id:, range:)
      Rails.logger.info('Projection Report refreshed :)'.light_cyan)
    end

    def tags_report(atos:)
      key = :spreadsheet_id_production_scheduling
      spreadsheet_id = Rails.application.credentials[key]
      Rails.logger.info('Refreshing Tags Report...'.light_cyan)
      atos.call(spreadsheet_id:)
      Rails.logger.info('Tags Report refreshed :)'.light_cyan)
    end

    def call(ancillary_input_params)
      checked_params = checked_params(input_params: ancillary_input_params)
      return if checked_params.empty?

      # @browser = Utils.watir_browser
      allmoxy_services = allmoxy_services(checked_params:)
      asrs = allmoxy_services[:asrs]
      aprs = allmoxy_services[:aprs]
      atos = allmoxy_services[:atos]

      shipping_report(asrs:) if asrs
      projection_report(aprs:) if aprs
      tags_report(atos:) if atos

      # @browser.close
    end
  end
end
