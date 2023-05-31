class BrowserService
  class AllmoxyOrdersReportDrawerService < AllmoxyOrdersReportService
    def call(spreadsheet_id:)
      range = 'boxes!A1:O'
      line = 'drawers'
      refresh_orders_report_input(spreadsheet_id:, range:, line:)
    end
  end
end
