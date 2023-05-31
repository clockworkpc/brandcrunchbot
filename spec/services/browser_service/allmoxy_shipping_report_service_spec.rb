require 'rails_helper'

RSpec.describe BrowserService::AllmoxyShippingReportService do
  let(:shipping_report) { CSV.read('spec/fixtures/shipping_report.csv') }
  let(:shipping_report_csv_path) { 'spec/fixtures/shipping_report.csv' }
  # let(:spreadsheet_id) { '1o79rNF6v7ZXBhxDyzL2EsxG4rE8cUAf0PKa2jaMdqio' }
  let(:spreadsheet_id) { '1n_GqOd2YkXv-gvTut0og_eeqeqj5wmuSgB9JSheX5GU' }
  let(:range_shipping_report) { 'shipping_report!A1:Z' }

  let(:start_date) { Utils.first_day_two_months_ago }
  let(:end_date) { Utils.last_day_two_months_hence }

  describe 'Without browser' do
    before(:all) do
      @service = described_class.new
    end

    describe 'Shipping Report' do
      it 'downloads shipping report via pseudo API', focus: true do
        csv0 = Dir.glob('tmp/**.csv').max_by { |f| File.mtime(f) }
        csv = @service.download_shipping_report(start_date:, end_date:)
        expect(CSV.read(csv)).not_to be_empty
        expect(csv).not_to eq(csv0)
      end

      it 'uploads a shipping report to the Google Sheet', focus: false do
        res = @service.upload_shipping_report(spreadsheet_id:, range: range_shipping_report,
                                              csv_path: shipping_report_csv_path)
        expect(res.spreadsheet_id).to eq(spreadsheet_id)
        expect(res.updated_range).to match('shipping_report!A1:K')
      end

      it 'refreshes a shipping report in Google Sheet from Allmoxy', focus: false do
        params = {
          spreadsheet_id:,
          range: range_shipping_report,
          start_date:,
          end_date:
        }
        @gs = GoogleSheetsApi.new
        res = @service.refresh_shipping_report_input(**params)
        dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: 'shipping_report!I2:I')
        shipping_dates = dates.values.map { |ary| DateTime.parse(ary.first) }.uniq.sort
        start_date = DateTime.parse(params[:start_date])
        end_date = DateTime.parse(params[:end_date])
        start_date_range = [start_date, start_date + 1, start_date + 2]
        end_date_month_range = [end_date.month, end_date.month - 1]
        expect(res.spreadsheet_id).to eq(spreadsheet_id)
        expect(res.updated_range).to match('shipping_report!A1:K')
        expect(start_date_range.include?(shipping_dates.min)).to be(true)
        expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
      end
    end
  end

  describe 'With browser' do
    before(:all) do
      @browser = Watir::Browser.new(:firefox)
      @as = described_class.new(@browser)
    end

    after(:all) do
      @browser.close
    end

    describe 'Shipping Report' do
      it 'downloads shipping report via pseudo API', focus: false do
        csv0 = Dir.glob('tmp/**.csv').max_by { |f| File.mtime(f) }
        csv = @as.download_shipping_report(start_date:, end_date:)
        expect(csv).not_to eq(csv0)
      end

      it 'uploads a shipping report to the Google Sheet' do
        res = @as.upload_shipping_report(spreadsheet_id:, range: range_shipping_report,
                                         csv_path: shipping_report_csv_path)
        expect(res.spreadsheet_id).to eq(spreadsheet_id)
        expect(res.updated_range).to match('shipping_report!A1:K')
      end

      it 'refreshes a shipping report in Google Sheet from Allmoxy', focus: false do
        params = {
          spreadsheet_id:,
          range: range_shipping_report,
          start_date:,
          end_date:
        }
        @gs = GoogleSheetsApi.new
        res = @as.refresh_shipping_report_input(**params)
        dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: 'shipping_report!I2:I')
        shipping_dates = dates.values.map { |ary| DateTime.parse(ary.first) }.uniq.sort
        start_date = DateTime.parse(params[:start_date])
        end_date = DateTime.parse(params[:end_date])
        start_date_range = [start_date, start_date + 1, start_date + 2]
        end_date_month_range = [end_date.month, end_date.month - 1]
        expect(res.spreadsheet_id).to eq(spreadsheet_id)
        expect(res.updated_range).to match('shipping_report!A1:K')
        expect(start_date_range.include?(shipping_dates.min)).to be(true)
        expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
      end
    end
  end
end
