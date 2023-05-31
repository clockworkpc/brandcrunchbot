class BrowserService
  class AllmoxyOrdersReportFinishService < AllmoxyOrdersReportService
    def call(spreadsheet_id:)
      line = 'finish'
      refresh_orders_report_input(spreadsheet_id:, line:)
    end
  end
end
