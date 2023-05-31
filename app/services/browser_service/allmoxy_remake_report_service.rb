class BrowserService
  class AllmoxyRemakeReportService < AllmoxyService
    def gsa
      @gsa ||= GoogleSheetsApi.new
    end

    def download_remake_report(start_date:, end_date:)
      # Visual confirmation of difference between previous CSV and new one
      csv0 = Utils.latest_csv_in_tmp
      puts "csv0: #{csv0}"
      # Associate POST request form parameters with PHPSESSID
      Rails.logger.info('Requesting a remake report'.light_cyan)
      @aas.remake_report_post(start_date:, end_date:)
      # GET request to download the CSV (stupid, I know)
      Rails.logger.info('Downloading a remake report'.light_cyan)
      @aas.remake_report_csv
      # Confirm that a CSV was downloaded
      csv1 = Utils.latest_csv_in_tmp
      puts "csv1: #{csv1}"

      if csv0 == csv1
        puts 'A new CSV was not downloaded: aborting upload.'
      else
        csv1
      end
    end

    def remake_report_with_dates(start_date:, end_date:, csv_path:)
      begin
        downloaded_csv = CSV.read(csv_path, headers: true)
      rescue CSV::MalformedCSVError
        Rails.logger.info("CSV for #{start_date} is empty.".light_red)
      end

      return unless downloaded_csv

      headers = downloaded_csv.headers
      ary = downloaded_csv.map do |row|
        hsh = { 'start_date' => start_date, 'end_date' => end_date }
        headers.each { |header| hsh[header] = row[header] }
        hsh
      end

      filename = "tmp/remake_report_#{DateTime.now.iso8601}.csv"

      CSV.open(filename, 'w') do |csv|
        headers = ary.flat_map(&:keys).uniq
        csv << headers
        ary.each { |hsh| csv << hsh.values_at(*headers) }
      end

      Rails.logger.info("#{filename} ready for upload".light_green)

      filename
    end

    def append_weekly_report(spreadsheet_id:, range:, start_date:)
      end_date = start_date + 6
      start_date_str = start_date.iso8601
      end_date_str = end_date.iso8601
      csv_path = download_remake_report(start_date: start_date_str,
                                        end_date: end_date_str)
      weekly_report_path = remake_report_with_dates(start_date: start_date_str,
                                                    end_date: end_date_str,
                                                    csv_path:)
      return unless weekly_report_path

      csv = CSV.read(weekly_report_path)
      values = csv[1..-1]
      gsa.append_spreadsheet_value(spreadsheet_id:, range:, values:)
    end

    def upload_remake_report(spreadsheet_id:, range:, csv_path:)
      gsa = GoogleSheetsApi.new
      Rails.logger.info("Clearing values from spreadsheet: #{spreadsheet_id}, range: #{range}".light_cyan)
      gsa.clear_values(spreadsheet_id:, range:)
      Rails.logger.info("Updating values in spreadsheet: #{spreadsheet_id}, range: #{range}".light_cyan)
      res = gsa.update_values(spreadsheet_id:, range:, csv_path:)
      Rails.logger.info('Values updated!'.light_cyan)
      res
    end

    def refresh_remake_report_input(spreadsheet_id:, start_date: nil, end_date: nil, range: 'remake_report!A1:K')
      start_date ||= Utils.first_day_two_months_ago
      end_date ||= Utils.last_day_two_months_hence

      csv_path = download_remake_report(start_date:, end_date:)
      return if csv_path.nil?

      upload_remake_report(spreadsheet_id:, range:, csv_path:)
    end

    def missing_days(spreadsheet_id:)
      start_dates = Utils.start_dates_to_date
      range = 'remake_report!A2:A'
      res = gsa.get_spreadsheet_values(spreadsheet_id:, range:)
      recorded_start_dates = res.values.nil? ? [] : res.values.flatten
      start_dates - recorded_start_dates
    end

    def update_remake_report_records(spreadsheet_id:, range: 'remake_report!A2:I')
      sheet_name = 'remake_report'
      last_column = 'I'
      clear_values_for_this_week(spreadsheet_id:, sheet_name:, last_column:)

      start_dates = Utils.start_dates_to_date
      missing_start_dates = missing_start_dates(start_dates:, spreadsheet_id:, sheet_name:)

      missing_start_dates.each do |start_date|
        append_weekly_report(spreadsheet_id:, range:, start_date:)
      end
    end
  end
end
