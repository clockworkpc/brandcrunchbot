require 'rails_helper'

RSpec.describe BrowserService::AllmoxyOrderFinishPriceService do
  let(:csv_path) { 'spec/fixtures/order_report_no_finish.csv' }

  before :all do
    @browser = Utils.watir_browser
  end

  after :all do
    @browser.close
  end
end
