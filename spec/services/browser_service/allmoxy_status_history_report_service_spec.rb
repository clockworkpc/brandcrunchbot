require 'rails_helper'

RSpec.describe BrowserService::AllmoxyStatusHistoryReportService do
  let(:start_date) { Date.current.prev_week + 7 }
  let(:end_date) { Date.current.next_occurring(:sunday) }
  let(:start_date_previous) { start_date - 7 }
  let(:end_date_previous) { end_date - 7 }
  let(:status_list) { ['bid', 'completed', 'in progress', 'ordered', 'shipped', 'verified'] }
  let(:export_class_list) do
    ['Doors', 'Doors - MDF Routed', 'Drawers', 'Paint Store', 'Shipping', 'Slabs', 'Specialty Products', 'Tax']
  end
  let(:upload_csv_headers_export_class) { %i[avg_per_working_day end_date export_class start_date status total] }
  let(:upload_csv_headers_product) { %i[avg_per_working_day end_date product start_date status total] }
  let(:range_export_class) { 'status_history_report_export_class!A2:F' }
  let(:range_product) { 'status_history_report_product!A2:F' }
  let(:spreadsheet_id) { Rails.application.credentials[:spreadsheet_id_finish_analysis] }

  before(:all) do
    @browser = Utils.watir_browser
    @service = described_class.new(@browser)
  end

  after(:all) do
    @browser.close
  end

  it 'downloads a status history report grouped by export class', focus: false do
    res = @service.download_status_history_report(start_date:, end_date:, group_by: 'export_class')
    csv = CSV.read(res, headers: true)
    expect(csv.pluck('Status').uniq.sort).to eq(status_list)
    expect(csv.pluck('Export class').uniq.sort).to eq(export_class_list)
  end

  it 'downloads a status history report grouped by product', focus: false do
    res = @service.download_status_history_report(start_date:, end_date:, group_by: 'product')
    csv = CSV.read(res, headers: true)
    expect(csv.headers.include?('Product')).to be(true)
    expect(csv.pluck('Status').uniq.sort).to eq(status_list)
  end

  it 'generates a CSV for upload for group by Export Class', focus: false do
    csv_path = @service.download_status_history_report(start_date:, end_date:, group_by: 'export_class')
    new_csv_path = @service.start_history_report_with_dates(start_date:, end_date:, csv_path:)
    csv = CSV.table(new_csv_path)
    expect(csv.headers.uniq.sort).to eq(upload_csv_headers_export_class)
  end

  it 'generates a CSV for upload for group by Product', focus: false do
    csv_path = @service.download_status_history_report(start_date:, end_date:, group_by: 'product')
    new_csv_path = @service.start_history_report_with_dates(start_date:, end_date:, csv_path:)
    csv = CSV.table(new_csv_path)
    expect(csv.headers.uniq.sort).to eq(upload_csv_headers_product)
  end

  it 'appends the values in status_history_report_export_class', focus: false do
    start_date = start_date_previous
    end_date = end_date_previous
    csv_download_path = @service.download_status_history_report(start_date:, end_date:, group_by: 'product')
    csv_path = @service.start_history_report_with_dates(start_date:, end_date:, csv_path: csv_download_path)
    res = @service.upload_status_history_report(spreadsheet_id:, range: range_export_class, csv_path:, start_date:)
  end

  it 'updates the status history report for Export Class', focus: false do
    res = @service.update_status_history_report(start_date:, end_date:, group_by: 'export_class')
    expect(res).to be_a(Google::Apis::SheetsV4::AppendValuesResponse)
    expect(res.spreadsheet_id).to eq(spreadsheet_id)
    expect(res.updates.updated_range).to match('export_class')
  end

  it 'updates the status history report for Product', focus: false do
    res = @service.update_status_history_report(start_date:, end_date:, group_by: 'product')
    expect(res).to be_a(Google::Apis::SheetsV4::AppendValuesResponse)
    expect(res.spreadsheet_id).to eq(spreadsheet_id)
    expect(res.updates.updated_range).to match('product')
  end
end
