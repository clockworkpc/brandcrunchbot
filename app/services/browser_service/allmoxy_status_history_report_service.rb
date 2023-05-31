class BrowserService
  class AllmoxyStatusHistoryReportService < AllmoxyService
    def download_status_history_report(start_date:, end_date:, group_by:)
      start_date_str = start_date.iso8601
      end_date_str = end_date.iso8601
      csv0 = Utils.latest_csv_in_tmp
      Rails.logger.info("csv0: #{csv0}".yellow)
      @aas.status_history_report_post(start_date: start_date_str,
                                      end_date: end_date_str,
                                      group_by:)
      @aas.status_history_report_csv
      csv1 = Utils.latest_csv_in_tmp
      Rails.logger.info("Status History Report CSV: #{csv1}".yellow)

      if csv0 == csv1
        Rails.logger.info('A new CSV was not downloaded: aborting upload.'.red)
      else
        csv1
      end
    end

    def status_history_report_with_dates(start_date:, end_date:, csv_path:, group_by:)
      downloaded_csv = CSV.read(csv_path, headers: true)
      headers = downloaded_csv.headers
      ary = downloaded_csv.map do |row|
        hsh = { 'start_date' => start_date.iso8601, 'end_date' => end_date.iso8601 }
        headers.each { |header| hsh[header] = row[header] }
        hsh
      end

      filename = "tmp/status_history_report_#{group_by}_#{DateTime.now.iso8601}.csv"

      CSV.open(filename, 'w') do |csv|
        headers = ary.flat_map(&:keys).uniq
        csv << headers
        ary.each { |hsh| csv << hsh.values_at(*headers) }
      end

      Rails.logger.info("#{filename} ready for upload".light_green)

      filename
    end

    def start_date_included_in_column?(start_date_column:, start_date:)
      start_dates = start_date_column.values.map(&:first).uniq.sort
      check = start_dates.include?(start_date.iso8601)
      if check
        message = "Values for the week of #{start_date.iso8601} aready in #{range}".light_red
        Rails.logger.info(message)
      end
      check
    end

    def get_spreadsheet_values(gsa:, spreadsheet_id:, range:)
      gsa.get_spreadsheet_values(spreadsheet_id:, range:)
    end

    def start_date_included_in_sheet?(gsa:, spreadsheet_id:, range:, start_date:)
      Rails.logger.info("Checking values in #{range}".yellow)
      check_range = [range.split('!').first, 'A2:A'].join('!')
      start_date_column = get_spreadsheet_values(gsa:, spreadsheet_id:, range: check_range)

      return false if start_date_column.values.nil?

      start_date_included_in_column?(start_date_column:, start_date:)
    end

    def upload_status_history_report(spreadsheet_id:, range:, csv_path:, start_date:, start_date_column: nil)
      gsa = GoogleSheetsApi.new

      start_date_included = if start_date_column
                              start_date_included_in_column?(start_date_column:, start_date:)
                            else
                              start_date_included_in_sheet?(gsa:, spreadsheet_id:, range:, start_date:)
                            end

      return if start_date_included

      Rails.logger.info("Updating values in #{range}".green)
      csv = CSV.read(csv_path)
      values = csv[1..-1]
      gsa.append_spreadsheet_value(spreadsheet_id:, range:, values:)
    end

    def update_status_history_report(start_date:, end_date:, group_by:, start_date_column: nil)
      csv_download_path = download_status_history_report(start_date:, end_date:, group_by:)
      csv_path = status_history_report_with_dates(start_date:, end_date:, csv_path: csv_download_path, group_by:)
      spreadsheet_id = Rails.application.credentials[:spreadsheet_id_finish_analysis]
      range = "status_history_report_#{group_by}!A2:H"
      upload_status_history_report(spreadsheet_id:, range:, csv_path:, start_date:, start_date_column:)
    end

    def batch_update_status_history_report(inputs:, start_date_column:)
      inputs.each do |hsh|
        start_date = hsh[:start_date]
        start_dates = start_date_column.values.map(&:first).uniq.sort
        start_date_included = start_dates.include?(start_date.iso8601)

        if start_date_included
          Rails.logger.info("Start Date #{start_date} already in sheet".light_red)
          next
        end

        end_date = hsh[:end_date]
        group_by = hsh[:group_by]

        update_status_history_report(start_date:, end_date:, group_by:, start_date_column:)
      end
    end

    def append_weekly_status_history_report(spreadsheet_id:, group_by:, start_date:)
      end_date = start_date + 6
      csv_path = download_status_history_report(start_date:,
                                                end_date:,
                                                group_by:)
      values_path = status_history_report_with_dates(start_date:,
                                                     end_date:,
                                                     csv_path:,
                                                     group_by:)
      csv = CSV.read(values_path)
      values = csv[1..-1]
      range = "status_history_report_#{group_by}!A2:H"
      gsa.append_spreadsheet_value(spreadsheet_id:, range:, values:)
    end

    def append_weekly_status_history_reports(spreadsheet_id:, group_by:, start_dates:)
      start_dates.each do |start_date|
        append_weekly_status_history_report(spreadsheet_id:, group_by:, start_date:)
      end
    end

    def clear_values_for_this_week_shr(spreadsheet_id:, group_by:)
      sheet_name = "status_history_report_#{group_by}"
      last_column = 'H'
      clear_values_for_this_week(spreadsheet_id:, sheet_name:, last_column:)
    end

    def clear_values_for_last_week_shr(spreadsheet_id:, group_by:)
      sheet_name = "status_history_report_#{group_by}"
      last_column = 'H'
      clear_values_for_this_week(spreadsheet_id:, sheet_name:, last_column:, last_integer: -2)
    end

    def update_weekly_status_history_reports(spreadsheet_id:, group_by:)
      clear_values_for_this_week_shr(spreadsheet_id:, group_by:)
      clear_values_for_last_week_shr(spreadsheet_id:, group_by:)
      all_start_dates = Utils.start_dates_to_date
      sheet_name = "status_history_report_#{group_by}"
      start_dates = missing_start_dates(start_dates: all_start_dates, spreadsheet_id:, sheet_name:)
      append_weekly_status_history_reports(spreadsheet_id:, group_by:, start_dates:)
    end
  end
end
