class BrowserService
  class AllmoxyOrdersReportDoorService < AllmoxyOrdersReportService
    def call(spreadsheet_id:, category:, statuses: nil)
      range = "#{category}!A1:O"
      line = 'doors'
      refresh_orders_report_input(spreadsheet_id:, range:, category:, statuses:, line:)
    end
  end
end
