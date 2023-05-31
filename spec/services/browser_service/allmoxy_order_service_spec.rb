require 'rails_helper'

RSpec.describe BrowserService::AllmoxyOrderService do
  let(:csv_path) { 'spec/fixtures/order_report_no_finish.csv' }
  let(order_numbers) { %w[84558 84909 84971 85068] }
  let(order_completion_dates) do
    {
      '84558' => '2023-01-01',
      '84909' => '2023-01-01',
      '84971' => '2023-01-01',
      '85068' => '2023-01-01'
    }
  end

  before(:all) do
    @browser = Utils.watir_browser
    FinishDetail.create
  end

  after(:all) do
    @browser.close
  end

  describe 'Orders with no finish', focus: false do
    it 'records the line subtotal but no finish price' do
      service = described_class.new(@browser, true)
      service.generate_order_records(csv_path:)
      product_orders = ProductOrder.last(3)
      product_orders.each do |product_order|
        pp product_order
        expect(product_order.finish_price).to eq(0)
      end
    end
  end

  describe 'Order Completion Date', focus: false do
    it 'retrieves the completion date for an Order' do
      service = described_class.new(@browser, true)
      res = service.completion_date(order_numbers:)
      expect(res).to eq(order_completion_dates)
    end
  end
end
