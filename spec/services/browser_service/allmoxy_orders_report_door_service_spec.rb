require 'rails_helper'

RSpec.describe BrowserService::AllmoxyOrdersReportDoorService do
  # let(:spreadsheet_id) { '1o79rNF6v7ZXBhxDyzL2EsxG4rE8cUAf0PKa2jaMdqio' } # PROD
  let(:spreadsheet_id) { '1FB7w2qujHSDfWcoaVEZ2lX4yREXH8ya7fiXiJjLptaQ' } # DEV

  let(:start_date) { Utils.first_day_two_months_ago }
  let(:end_date) { Utils.last_day_two_months_hence }

  before(:all) do
    @browser = Watir::Browser.new(:firefox)
    @door_service = described_class.new(@browser, true)
  end

  after(:all) do
    @browser.close
  end

  describe 'Orders Report for Doors sanded', skip: false do
    it 'refreshes a Doors Orders Report for sanded', focus: false do
      category = 'sanded'
      @gs = GoogleSheetsApi.new
      res = @door_service.refresh_orders_report_input(spreadsheet_id:, category:)
      dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: 'sanded!H2:H')
      shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%Y-%m-%d') }
      end_date_month = DateTime.parse(end_date).month
      end_date_month_range = [end_date_month, end_date_month - 1]
      expect(res.spreadsheet_id).to eq(spreadsheet_id)
      expect(res.updated_range).to match("#{category}!A1:O")
      expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
    end

    it 'refreshes a Doors Orders Report for 5pc', focus: false do
      category = '5pc'
      @gs = GoogleSheetsApi.new
      res = @door_service.refresh_orders_report_input(spreadsheet_id:, category:)
      dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: "#{category}!H2:H")
      shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%Y-%m-%d') }
      end_date_month = DateTime.parse(end_date).month
      end_date_month_range = [end_date_month, end_date_month - 1]
      expect(res.spreadsheet_id).to eq(spreadsheet_id)
      expect(res.updated_range).to match("'#{category}'!A1:O")
      expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
    end

    it 'refreshes a Doors Orders Report for solidwood', focus: false do
      category = 'solidwood'
      @gs = GoogleSheetsApi.new
      res = @door_service.refresh_orders_report_input(spreadsheet_id:, category:)
      dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: "#{category}!H2:H")
      shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%Y-%m-%d') }
      end_date_month = DateTime.parse(end_date).month
      end_date_month_range = [end_date_month, end_date_month - 1]
      expect(res.spreadsheet_id).to eq(spreadsheet_id)
      expect(res.updated_range).to match("#{category}!A1:O")
      expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
    end

    it 'refreshes a Doors Orders Report for cnc', focus: false do
      category = 'cnc'
      @gs = GoogleSheetsApi.new
      res = @door_service.refresh_orders_report_input(spreadsheet_id:, category:)
      dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: "#{category}!H2:H")
      shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%Y-%m-%d') }
      end_date_month = DateTime.parse(end_date).month
      end_date_month_range = [end_date_month, end_date_month - 1]
      expect(res.spreadsheet_id).to eq(spreadsheet_id)
      expect(res.updated_range).to match("#{category}!A1:O")
      expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
    end

    it 'refreshes a Doors Orders Report for sanded_panels', focus: false do
      category = 'sanded_panels'
      @gs = GoogleSheetsApi.new
      res = @door_service.refresh_orders_report_input(spreadsheet_id:, category:)
      dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: "#{category}!H2:H")
      shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%Y-%m-%d') }
      end_date_month = DateTime.parse(end_date).month
      end_date_month_range = [end_date_month, end_date_month - 1]
      expect(res.spreadsheet_id).to eq(spreadsheet_id)
      expect(res.updated_range).to match("#{category}!A1:O")
    end
  end
end
