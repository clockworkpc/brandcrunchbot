require 'rails_helper'

RSpec.describe ProductOrderService do
  let(:spreadsheet_id) { Rails.application.credentials[:spreadsheet_id_finish_analysis] }
  let(:sample_orders_csv) { CSV.table('spec/fixtures/orders_test_finish_price_analysis.csv') }

  let(:start_date) { '2022-01-01' }
  let(:end_date) { '2022-01-30' }
  let(:range) { 'orders_test!A1:G' }

  before(:all) do
    @gsa = GoogleSheetsApi.new
    @service = described_class.new(@gsa)
  end

  before do
    dummy_data_from_csv
    dummy_data_from_factory
  end

  it 'updates the sheet', focus: true do
    @service.update_finish_price_tracking(spreadsheet_id:, range:, start_date:, end_date:)
  end

  def dummy_data_from_csv
    sample_orders_csv = CSV.table('spec/fixtures/orders_test_finish_price_analysis.csv')
    sample_orders_csv.each do |row|
      finish_detail = create(:finish_detail)
      customer = Customer.find_or_create_by(customer_name: row[:customer_name])
      completed_at = Date.parse(row[:completed_at])
      ship_date = completed_at + 3
      order_number = row[:order_number]

      order = Order.find_or_create_by(order_number:, ship_date:, completed_at:, customer:)
      product = Product.find_or_create_by(product_name: row[:product_name])

      line_subtotal = row[:line_subtotal]
      finish_price = row[:finish_price]
      qty = row[:qty]

      ProductOrder.find_or_create_by(order:, product:, finish_detail:, line_subtotal:, finish_price:, qty:)
    end
  end

  def dummy_data_from_factory
    finish_details = create_list(:finish_detail, 3)
    products = create_list(:product, 3)
    customers = create_list(:customer, 3)

    orders = customers.map do |customer|
      create(:order, customer:, ship_date: (start_date..end_date).to_a.sample)
    end

    orders.each do |order|
      products.each do |product|
        finish_details.each do |finish_detail|
          create(:product_order, order:, product:, finish_detail:)
        end
      end
    end
  end
end
