require 'rails_helper'

RSpec.describe BrowserService::AllmoxyProductReportService do
  before(:all) do
    @browser = Watir::Browser.new
    @service = described_class.new(@browser, true)
  end

  describe 'Product Tag Report' do
    it 'refreshes the product tag report', focus: false do
      spreadsheet_id = Rails.application.credentials[:spreadsheet_id_settings_v5]
      @service.refresh_product_tags_report(spreadsheet_id:)
    end
  end
end
