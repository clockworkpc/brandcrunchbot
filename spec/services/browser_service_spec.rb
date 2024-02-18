require 'rails_helper'

RSpec.describe BrowserService do
  describe 'Finish Prices' do
    before do
      @browser = Watir::Browser.new(:firefox)
    end

    after do
      @browser.close
    end

    # it 'retrieves Finish Prices for an Order' do
    #   b = described_class.new(@browser)
    #   b.sign_in
    #   b.goto_finish_price(66_817)
    #   b.collect_finish_prices('66817')
    # end

    it 'writes Finish Prices for an Order' do
      orders = [66_817, 67_110]
      b = described_class.new(@browser)
      b.sign_in
      b.add_finish_prices_to_csv(orders)
    end
  end
end
