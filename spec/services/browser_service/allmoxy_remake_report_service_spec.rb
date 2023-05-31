require 'rails_helper'

RSpec.describe BrowserService::AllmoxyRemakeReportService do
  let(:remake_report) { CSV.read('spec/fixtures/remake_report.csv') }
  let(:remake_report_csv_path) { 'spec/fixtures/remake_report.csv' }
  # let(:spreadsheet_id) { '1o79rNF6v7ZXBhxDyzL2EsxG4rE8cUAf0PKa2jaMdqio' }
  let(:spreadsheet_id) { Rails.application.credentials[:spreadsheet_id_gainsharing] }
  let(:range_remake_report) { 'remake_report!A1:Z' }

  let(:start_date) { Utils.first_day_two_months_ago }
  let(:end_date) { Utils.last_day_two_months_hence }

  before(:all) do
    @browser = Watir::Browser.new(:firefox)
    @service = described_class.new(@browser)
  end

  after(:all) do
    @browser.close
  end

  describe 'Remake Report' do
    it 'downloads remake report via pseudo API', focus: false do
      csv0 = Dir.glob('tmp/**.csv').max_by { |f| File.mtime(f) }
      csv = @service.download_remake_report(start_date:, end_date:)
      expect(csv).not_to eq(csv0)
    end

    it 'adds start and end date to the report', focus: false do
      csv_path = @service.download_remake_report(start_date:, end_date:)
      new_csv_path = @service.remake_report_with_dates(start_date:, end_date:, csv_path:)
      csv = CSV.table(new_csv_path, headers: true)
    end

    it 'appends daily remake reports', focus: true do
      @service.update_remake_report_records(spreadsheet_id:)
    end

    it 'uploads a remake report to the Google Sheet' do
      res = @service.upload_remake_report(spreadsheet_id:, range: range_remake_report,
                                          csv_path: remake_report_csv_path)
      expect(res.spreadsheet_id).to eq(spreadsheet_id)
      expect(res.updated_range).to match('remake_report!A1:K')
    end

    it 'refreshes a remake report in Google Sheet from Allmoxy', focus: false do
      params = {
        spreadsheet_id:,
        range: range_remake_report,
        start_date:,
        end_date:
      }
      @gs = GoogleSheetsApi.new
      res = @service.refresh_remake_report_input(**params)
      dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: 'remake_report!I2:I')
      remake_dates = dates.values.map { |ary| DateTime.parse(ary.first) }.uniq.sort
      start_date = DateTime.parse(params[:start_date])
      end_date = DateTime.parse(params[:end_date])
      start_date_range = [start_date, start_date + 1, start_date + 2]
      end_date_month_range = [end_date.month, end_date.month - 1]
      expect(res.spreadsheet_id).to eq(spreadsheet_id)
      expect(res.updated_range).to match('remake_report!A1:K')
      expect(start_date_range.include?(remake_dates.min)).to be(true)
      expect(end_date_month_range.include?(remake_dates.max.month)).to be(true)
    end
  end
end
