require 'rails_helper'

RSpec.describe AllmoxyApiBeta::OrderProductService do
  let(:order_products_json) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/order_products.json')) }

  before(:all) do
    @service = described_class.new
  end

  describe 'GET Requests' do
    # FIXME: Add Order records
    it 'gets all orders', focus: true do
      res = @service.order_products
      expect(res).to eq(order_products_json)
      expect(res['entries']).not_to be_empty
    end

    # # FIXME: No record to test against
    # it 'gets order WHERE order_id=1', focus: true do
    #   res, entry = test_entry(order_id: 1)
    #   pp res
    #   expect(res).to eq(entry)
    # end

    # # FIXME: No record to test against
    # it 'gets order WHERE order_id=2', focus: false do
    #   res, entry = test_entry(order_id: 2)
    #   expect(res).to eq(entry)
    # end

    # # FIXME: No record to test against
    # it 'gets order WHERE order_id=3', focus: false do
    #   res, entry = test_entry(order_id: 3)
    #   expect(res).to eq(entry)
    # end
  end

  def find_entry(order_id)
    orders_json['entries'].find { |e| e['order_id'] == order_id }
  end

  def test_entry(order_id:)
    res = @service.orders(order_id:)
    entry = find_entry(order_id)
    [res, entry]
  end
end
