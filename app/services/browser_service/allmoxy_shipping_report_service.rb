class BrowserService
  class AllmoxyShippingReportService < AllmoxyService
    def download_shipping_report(start_date:, end_date:)
      # Visual confirmation of difference between previous CSV and new one
      csv0 = Utils.latest_csv_in_tmp
      puts "csv0: #{csv0}"
      # Associate POST request form parameters with PHPSESSID
      Rails.logger.info('Requesting a shipping report'.light_cyan)
      post_response = @aas.shipping_report_post(start_date:, end_date:)
      # GET request to download the CSV (stupid, I know)
      Rails.logger.info('Downloading a shipping report'.light_cyan)
      @aas.shipping_report_csv
      # Confirm that a CSV was downloaded
      csv1 = Utils.latest_csv_in_tmp
      puts "csv1: #{csv1}"

      if csv0 == csv1
        puts 'A new CSV was not downloaded: aborting upload.'
      else
        csv1
      end
    end

    def upload_shipping_report(spreadsheet_id:, range:, csv_path:)
      gsa = GoogleSheetsApi.new
      Rails.logger.info("Clearing values from spreadsheet: #{spreadsheet_id}, range: #{range}".light_cyan)
      gsa.clear_values(spreadsheet_id:, range:)
      Rails.logger.info("Updating values in spreadsheet: #{spreadsheet_id}, range: #{range}".light_cyan)
      res = gsa.update_values(spreadsheet_id:, range:, csv_path:)
      Rails.logger.info('Values updated!'.light_cyan)
      res
    end

    def refresh_shipping_report_input(spreadsheet_id:, start_date: nil, end_date: nil, range: 'shipping_report!A1:K')
      start_date ||= Utils.first_day_two_months_ago
      end_date ||= Utils.last_day_two_months_hence

      csv_path = download_shipping_report(start_date:, end_date:)
      return if csv_path.nil?

      upload_shipping_report(spreadsheet_id:, range:, csv_path:)
    end
  end
end