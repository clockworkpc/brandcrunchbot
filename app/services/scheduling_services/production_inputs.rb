module SchedulingServices
  class ProductionInputs < SchedulingInputs
    DOOR_CATEGORIES = %w[doors_solid doors_slab doors_flat doors_routed doors_miter doors_finished
                         doors_specialty].freeze
    DRAWER_CATEGORIES = %w[drawers_solid drawers_baltic drawers_logos drawers_specialty].freeze

    def allmoxy_services(checked_params:)
      doors = -> { checked_params.key?('doors_inputs') }
      drawers = -> { checked_params.key?('drawers_inputs') }
      specialty = -> { checked_params.key?('specialty_inputs') }

      door_order_service = BrowserService::ProductionScheduleDoorService.new(@browser) if doors.call
      drawer_order_service = BrowserService::ProductionScheduleDrawerService.new(@browser) if drawers.call
      specialty_order_service = BrowserService::AllmoxyOrdersReportSpecialtyService.new(@browser) if specialty.call
      {
        door_order_service:,
        drawer_order_service:,
        specialty_order_service:
      }
    end

    def door_orders(door_order_service:, sas_parent:)
      return unless door_order_service

      key = :spreadsheet_id_production_scheduling
      spreadsheet_id = Rails.application.credentials[key]
      statuses = ['verified', 'in progress']

      DOOR_CATEGORIES.each do |category|
        text_start = "Refreshing Orders Report for Doors ##{category}..."
        Rails.logger.info(text_start.light_cyan)
        sas.post_reply(sas_parent:, text: text_start)

        door_order_service.call(spreadsheet_id:, category:, statuses:)
        text_complete = "Orders Report for Doors ##{category} refreshed."
        Rails.logger.info(text_complete.light_cyan)
        sas.post_reply(sas_parent:, text: text_complete)
      end
      door_order_service.refresh_rush_jobs(spreadsheet_id:)
    end

    def drawer_orders(drawer_order_service:, sas_parent:)
      return unless drawer_order_service

      key = :spreadsheet_id_production_scheduling
      spreadsheet_id = Rails.application.credentials[key]
      statuses = ['verified', 'in progress']

      DRAWER_CATEGORIES.each do |category|
        text_start = "Refreshing Orders Report for Drawers ##{category}..."
        Rails.logger.info(text_start.light_cyan)
        sas.post_reply(sas_parent:, text: text_start)

        drawer_order_service.call(spreadsheet_id:, category:, statuses:)
        text_complete = "Orders Report for Drawers ##{category} refreshed."
        Rails.logger.info(text_complete.light_cyan)
        sas.post_reply(sas_parent:, text: text_complete)
      end
    end

    def specialty_orders(specialty_order_service:, sas_parent:)
      key = :spreadsheet_id_scheduling_inputs_prod
      spreadsheet_id = Rails.application.credentials[key]
      # statuses = ['verified', 'in progress']
      text_start = 'Refreshing Orders Report for Specialty...'
      Rails.logger.info(text_start.light_cyan)
      sas.post_reply(sas_parent:, text: text_start)

      specialty_order_service.call(spreadsheet_id:)
      text_complete = 'Orders Report for Specialty refreshed.'
      Rails.logger.info(text_complete.light_cyan)
      sas.post_reply(sas_parent:, text: text_complete)
    end

    def call(production_input_params)
      checked_params = checked_params(input_params: production_input_params)
      sas_parent = refresh_reports_slack_parent(checked_params:)
      return if checked_params.empty?

      # @browser = Utils.watir_browser

      begin
        allmoxy_services = allmoxy_services(checked_params:)
        door_order_service = allmoxy_services[:door_order_service]
        drawer_order_service = allmoxy_services[:drawer_order_service]
        specialty_order_service = allmoxy_services[:specialty_order_service]

        door_orders(door_order_service:, sas_parent:)
        drawer_orders(drawer_order_service:, sas_parent:)
        specialty_orders(specialty_order_service:, sas_parent:)
      rescue StandardError => e
        Rails.logger.info(e)
      ensure
        # @browser.close
        Rails.logger.info('Browser closed')
      end

      # @browser = Utils.watir_browser

      begin
        Rails.logger.info('Browser re-opened')
        ohs_service = BrowserService::AllmoxyOrderHistoryService.new(@browser)
        ohs_service.update_verified_order_history_sheet
      rescue StandardError => e
        Rails.logger.info(e)
      ensure
        Rails.logger.info('Browser closed')
        @browser.close
      end
    end
  end
end
