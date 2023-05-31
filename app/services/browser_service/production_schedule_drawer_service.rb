class BrowserService
  class ProductionScheduleDrawerService < AllmoxyOrdersReportDrawerService
    def call(spreadsheet_id:, category:, statuses: ['verified'])
      Rails.logger.info("Statuses: #{statuses.join(', ')}".green)
      range = "#{category}!A1:O"
      line = 'drawers'
      refresh_orders_report_input(spreadsheet_id:, range:, category:, statuses:, line:)
    end
  end
end
