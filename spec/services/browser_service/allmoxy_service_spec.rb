# require 'rails_helper'

# RSpec.describe BrowserService::AllmoxyService do
#   let(:door_order_params) do
#     {
#       name: nil,
#       status: {
#         verified: 1,
#         'in progress': 1
#       },
#       start_date: '2022-06-18',
#       end_date: '2022-07-18',
#       tags_any_Order: [
#         { caption: 'DoorFinish', value: 85 },
#         { caption: 'solid', value: 100 },
#         { caption: 'unfinished', value: 86 }
#       ]
#     }
#   end

#   let(:shipping_report) { CSV.read('spec/fixtures/shipping_report.csv') }

#   # let(:spreadsheet_id) { '1o79rNF6v7ZXBhxDyzL2EsxG4rE8cUAf0PKa2jaMdqio' }
#   let(:spreadsheet_id) { '1n_GqOd2YkXv-gvTut0og_eeqeqj5wmuSgB9JSheX5GU' }
#   let(:range_shipping_report) { 'shipping_report!A1:Z' }
#   let(:range_orders_report) { 'shipping_report!A1:Z' }

#   let(:shipping_report_csv_path) { 'spec/fixtures/shipping_report.csv' }

#   let(:start_date) { Utils.first_day_two_months_ago }
#   let(:end_date) { Utils.last_day_two_months_hence }

#   before(:all) do
#     @browser = Watir::Browser.new(:firefox)
#     @as = described_class.new(@browser)
#   end

#   after(:all) do
#     @browser.close
#   end

#   # describe 'Shipping Report' do
#   #   it 'downloads shipping report via pseudo API' do
#   #     csv0 = Dir.glob("#{downloads}/**.csv").max_by { |f| File.mtime(f) }
#   #     start_date = start_date
#   #     end_date = end_date
#   #     csv = @as.download_shipping_report(start_date:, end_date:)
#   #     expect(csv).not_to eq(csv0)
#   #   end

#   #   it 'uploads a shipping report to the Google Sheet' do
#   #     res = @as.upload_shipping_report(spreadsheet_id:, range: range_shipping_report,
#   #                                      csv_path: shipping_report_csv_path)
#   #     expect(res.spreadsheet_id).to eq(spreadsheet_id)
#   #     expect(res.updated_range).to match(range_shipping_report)
#   #   end

#   #   it 'refreshes a shipping report in Google Sheet from Allmoxy', focus: false do
#   #     params = {
#   #       spreadsheet_id:,
#   #       range: range_shipping_report,
#   #       start_date:,
#   #       end_date:
#   #     }
#   #     @gs = GoogleSheetsApi.new
#   #     res = @as.refresh_shipping_report_input(**params)
#   #     dates = @gs.get_spreadsheet_values(spreadsheet_id:, sheet_name: 'shipping_report', range_str: 'I2:I')
#   #     shipping_dates = dates.values.map { |ary| DateTime.parse(ary.first) }.uniq.sort
#   #     start_date = DateTime.parse(params[:start_date])
#   #     end_date = DateTime.parse(params[:end_date])
#   #     start_date_range = [start_date, start_date + 1, start_date + 2]
#   #     end_date_month_range = [end_date.month, end_date.month - 1]
#   #     expect(res.spreadsheet_id).to eq(spreadsheet_id)
#   #     expect(res.updated_range).to match('shipping_report!A1:K')
#   #     expect(start_date_range.include?(shipping_dates.min)).to be(true)
#   #     expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
#   #   end
#   # end

#   describe 'Orders Report', skip: false do
#     it 'refreshes a Doors Orders Report', focus: false do
#       params = {
#         spreadsheet_id:,
#         start_date:,
#         end_date:,
#         line: 'doors',
#         statuses: ['verified', 'in progress']
#       }
#       @gs = GoogleSheetsApi.new
#       # res = @as.refresh_orders_report_input(**params)
#       res = @as.refresh_orders_report_input_doors(spreadsheet_id:)
#       dates = @gs.get_spreadsheet_values(spreadsheet_id:, sheet_name: 'doors', range_str: 'H2:H')
#       shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%m/%d/%Y') }
#       # start_date = DateTime.parse(params[:start_date])
#       end_date = DateTime.parse(params[:end_date])
#       # start_date_range = [start_date, start_date + 1, start_date + 2]
#       end_date_month_range = [end_date.month, end_date.month - 1]
#       expect(res.spreadsheet_id).to eq(spreadsheet_id)
#       expect(res.updated_range).to match('doors!A1:O')
#       # expect(start_date_range.include?(shipping_dates.min.to_datetime)).to be(true)
#       expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
#     end

#     it 'refreshes a Boxes Orders Report', focus: false do
#       params = {
#         spreadsheet_id:,
#         start_date:,
#         end_date:,
#         line: 'boxes',
#         statuses: ['verified', 'in progress']
#       }
#       @gs = GoogleSheetsApi.new
#       res = @as.refresh_orders_report_input_boxes(spreadsheet_id:)
#       dates = @gs.get_spreadsheet_values(spreadsheet_id:, sheet_name: 'boxes', range_str: 'H2:H')
#       shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%m/%d/%Y') }
#       end_date = DateTime.parse(params[:end_date])
#       end_date_month_range = [end_date.month, end_date.month - 1]
#       expect(res.updated_range).to match('boxes!A1:O')
#       expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
#     end

#     it 'refreshes a Specialty Orders Report', focus: false do
#       params = {
#         spreadsheet_id:,
#         start_date:,
#         end_date:,
#         line: 'specialty',
#         statuses: ['verified', 'in progress']
#       }
#       @gs = GoogleSheetsApi.new
#       res = @as.refresh_orders_report_input_specialty(spreadsheet_id:)
#       dates = @gs.get_spreadsheet_values(spreadsheet_id:, sheet_name: 'specialty', range_str: 'H2:H')
#       shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%m/%d/%Y') }
#       end_date = DateTime.parse(params[:end_date])
#       end_date_month_range = [end_date.month, end_date.month - 1]
#       expect(res.updated_range).to match('specialty!A1:O')
#       expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
#     end

#     it 'refreshes a Finish Orders Report', focus: false do
#       params = {
#         spreadsheet_id:,
#         start_date:,
#         end_date:,
#         line: 'finish',
#         statuses: ['verified', 'in progress']
#       }
#       @gs = GoogleSheetsApi.new
#       res = @as.refresh_orders_report_input_finish(spreadsheet_id:)
#       dates = @gs.get_spreadsheet_values(spreadsheet_id:, sheet_name: 'finish', range_str: 'H2:H')
#       shipping_dates = dates.values.uniq.sort.map { |ary| Date.strptime(ary.first, '%m/%d/%Y') }
#       end_date = DateTime.parse(params[:end_date])
#       end_date_month_range = [end_date.month, end_date.month - 1]
#       expect(res.updated_range).to match('finish!A1:O')
#       expect(end_date_month_range.include?(shipping_dates.max.month)).to be(true)
#     end
#   end
# end
