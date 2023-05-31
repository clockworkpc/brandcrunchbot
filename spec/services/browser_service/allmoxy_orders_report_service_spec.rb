require 'rails_helper'

RSpec.describe BrowserService::AllmoxyOrdersReportService do
  # let(:spreadsheet_id) { '1o79rNF6v7ZXBhxDyzL2EsxG4rE8cUAf0PKa2jaMdqio' } # PROD
  let(:spreadsheet_id) { '1n_GqOd2YkXv-gvTut0og_eeqeqj5wmuSgB9JSheX5GU' } # DEV

  let(:door_order_params) do
    {
      name: nil,
      status: {
        verified: 1,
        'in progress': 1
      },
      start_date: '2022-06-18',
      end_date: '2022-07-18',
      tags_any_Order: [
        { caption: 'DoorFinish', value: 85 },
        { caption: 'solid', value: 100 },
        { caption: 'unfinished', value: 86 }
      ]
    }
  end

  let(:range_orders_report) { 'shipping_report!A1:Z' }

  let(:start_date) { Utils.first_day_two_months_ago }
  let(:end_date) { Utils.last_day_two_months_hence }

  before(:all) do
    @browser = Watir::Browser.new(:firefox)
    @service = described_class.new(@browser)
    @gs = GoogleSheetsApi.new
  end

  after(:all) do
    @browser.close
  end

  describe 'Orders Report', skip: false do
    it 'refreshes a Doors Orders Report', focus: false do
      params = {
        spreadsheet_id:,
        start_date:,
        end_date:,
        line: 'doors',
        statuses: ['verified', 'in progress']
      }
      # res = @service.refresh_orders_report_input(**params)
      res = @service.refresh_orders_report_input_doors(spreadsheet_id:)
      dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: 'doors!H2:H')
      shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%m/%d/%Y') }
      # start_date = DateTime.parse(params[:start_date])
      end_date = DateTime.parse(params[:end_date])
      # start_date_range = [start_date, start_date + 1, start_date + 2]
      end_date_month_range = [end_date.month, end_date.month - 1]
      expect(res.spreadsheet_id).to eq(spreadsheet_id)
      expect(res.updated_range).to match('doors!A1:O')
      # expect(start_date_range.include?(shipping_dates.min.to_datetime)).to be(true)
      expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
    end

    it 'refreshes a Boxes Orders Report', focus: false do
      params = {
        spreadsheet_id:,
        start_date:,
        end_date:,
        line: 'boxes',
        statuses: ['verified', 'in progress']
      }
      res = @service.refresh_orders_report_input_boxes(spreadsheet_id:)
      dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: 'boxes!H2:H')
      shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%m/%d/%Y') }
      end_date = DateTime.parse(params[:end_date])
      end_date_month_range = [end_date.month, end_date.month - 1]
      expect(res.updated_range).to match('boxes!A1:O')
      expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
    end

    it 'refreshes a Specialty Orders Report', focus: false do
      params = {
        spreadsheet_id:,
        start_date:,
        end_date:,
        line: 'specialty',
        statuses: ['verified', 'in progress']
      }

      res = @service.refresh_orders_report_input_specialty(spreadsheet_id:)
      dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: 'specialty!H2:H')
      shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%m/%d/%Y') }
      end_date = DateTime.parse(params[:end_date])
      end_date_month_range = [end_date.month, end_date.month - 1]
      expect(res.updated_range).to match('specialty!A1:O')
      expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
    end

    it 'refreshes a Finish Orders Report', focus: false do
      params = {
        spreadsheet_id:,
        start_date:,
        end_date:,
        line: 'finish',
        statuses: ['verified', 'in progress']
      }

      res = @service.refresh_orders_report_input_finish(spreadsheet_id:)
      dates = @gs.get_spreadsheet_values(spreadsheet_id:, range: 'finish!H2:H')
      shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%m/%d/%Y') }
      end_date = DateTime.parse(params[:end_date])
      end_date_month_range = [end_date.month, end_date.month - 1]
      expect(res.updated_range).to match('finish!A1:O')
      expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
    end

    it 'refreshes the Finish Price Tracking sheet', focus: false do
      spreadsheet_id = Rails.application.credentials(:spreadsheet_id_finish_analysis)
      res = @service.update_finish_price_tracking(spreadsheet_id:)
    end
  end
end
