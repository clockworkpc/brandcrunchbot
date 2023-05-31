module SchedulingServices
  class AnalysisInputs < SchedulingInputs
    def call # rubocop:disable Metrics/MethodLength
      text = 'Updating Order Report for Finish Pricing Analysis'
      sas.post_message(text:)

      key = :spreadsheet_id_finish_analysis
      spreadsheet_id = Rails.application.credentials[key]
      range = 'orders_input!A1:Z'
      start_date = [Date.current.year, '01', '01'].join('-')
      end_date = [Date.current.year, '12', '31'].join('-')
      statuses = %w[completed shipped]
      line = 'all'

      begin
        @browser = Utils.watir_browser
        service = BrowserService::AllmoxyOrdersReportService.new(@browser)
        service.refresh_orders_report_input(spreadsheet_id:,
                                            range:,
                                            start_date:,
                                            end_date:,
                                            statuses:,
                                            line:)
      rescue StandardError => e
        @browser.close
        Rails.logger.info(e)
      ensure
        @browser.close
      end
    end
  end
end
