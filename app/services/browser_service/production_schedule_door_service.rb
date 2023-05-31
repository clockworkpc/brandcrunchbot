class BrowserService
  class ProductionScheduleDoorService < AllmoxyOrdersReportDoorService
    def refresh_door_orders(spreadsheet_id:, category:, statuses:)
      Rails.logger.info("Statuses: #{statuses.join(', ')}".green)
      range = "#{category}!A1:O"
      line = 'doors'
      refresh_orders_report_input(spreadsheet_id:, range:, category:, statuses:, line:)
    end

    def refresh_rush_jobs(spreadsheet_id:)
      range = 'rush_jobs!A1:O'
      line = 'rush_jobs'
      statuses = ['verified', 'in progress']
      refresh_orders_report_input(spreadsheet_id:, range:, statuses:, line:)
    end

    def call(spreadsheet_id:, category:, statuses: ['verified', 'in progress'])
      refresh_door_orders(spreadsheet_id:, category:, statuses:)
    end
  end
end
