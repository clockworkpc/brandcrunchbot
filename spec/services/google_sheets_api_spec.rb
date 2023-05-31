require 'rails_helper'

RSpec.describe GoogleSheetsApi do
  let(:spreadsheet_id) { '1n_GqOd2YkXv-gvTut0og_eeqeqj5wmuSgB9JSheX5GU' }
  let(:range_sr) { 'shipping_report!A1:Z' }
  let(:shipping_report_csv_path) { 'spec/fixtures/shipping_report.csv' }

  describe 'Inputs' do
    it 'clears values from shipping_report_test', focus: false do
      gsa = described_class.new
      res = gsa.clear_values(spreadsheet_id:, range: range_sr)
      expect(res.cleared_range).to match(range_sr)
      expect(res.spreadsheet_id).to eq(spreadsheet_id)
    end

    it 'writes values into shipping_report_test', focus: true do
      gsa = described_class.new
      res = gsa.update_values(spreadsheet_id:, range: range_sr, csv_path: shipping_report_csv_path)
    end
  end
end
