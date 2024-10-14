require 'rails_helper'

RSpec.describe GoogleSheetsApi do
  let(:spreadsheet_id) { '1VVKoz1xM3NITzIRdRvB5l-Qp4_9updmot0Ry4yxKDC8' }

  describe 'Inputs' do
    it 'reads values from domains', :focus do
      gsa = described_class.new
      range = 'domains!A1:C'
      res = gsa.get_spreadsheet_values(spreadsheet_id:, range:)
      pp res
      expect { gsa.get_spreadsheet_values(spreadsheet_id:, range:) }.not_to raise_error
    end

    # it 'clears values from shipping_report_test', focus: false do
    #   gsa = described_class.new
    #   res = gsa.clear_values(spreadsheet_id:, range: range_sr)
    #   expect(res.cleared_range).to match(range_sr)
    #   expect(res.spreadsheet_id).to eq(spreadsheet_id)
    # end
    #
    # it 'writes values into shipping_report_test', focus: false do
    #   gsa = described_class.new
    #   res = gsa.update_values(spreadsheet_id:, range: range_sr, csv_path: shipping_report_csv_path)
    # end
  end
end
