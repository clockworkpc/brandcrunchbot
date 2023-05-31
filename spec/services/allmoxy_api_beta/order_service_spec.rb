require 'rails_helper'

RSpec.describe AllmoxyApiBeta::OrderService do
  let(:orders_json) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/orders.json')) }
  let(:order_body) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/order_template.json')).deep_symbolize_keys }

  before(:all) do
    @service = described_class.new
  end

  describe 'POST Requests' do
    it 'creates a new order', focus: true do
      timestamp = DateTime.now.strftime('%Y%m%dT%H%M').delete('T')
      body = {
        name: "Foobar Test #{timestamp}",
        description: 'This is a test'
      }
      res = @service.create_order(body:)
    end
  end

  describe 'GET Requests' do
    # FIXME: Add Order records
    it 'gets all orders', focus: false do
      res = @service.orders
      expect(res['entries']).not_to be_empty
      expect(res['entries'].count > 1).to be(false)
    end

    # FIXME: No record to test against
    it 'gets order WHERE order_id=1', focus: false do
      res, entry = test_entry(order_id: 3)
      pp res
      expect(res).to eq(entry)
    end

    # FIXME: No record to test against
    it 'gets order WHERE order_id=2', focus: false do
      res, entry = test_entry(order_id: 2)
      expect(res).to eq(entry)
    end

    # FIXME: No record to test against
    it 'gets order WHERE order_id=3', focus: false do
      res, entry = test_entry(order_id: 3)
      expect(res).to eq(entry)
    end
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
