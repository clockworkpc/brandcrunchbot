require 'rails_helper'

RSpec.describe AllmoxyApiBeta::OrderStatusHistoryService do
  let(:order_status_history_json) { JSON.parse(File.read('spec/fixtures/allmoxy_api_beta/order_status_history.json')) }

  before(:all) do
    @service = described_class.new
  end

  describe 'GET Requests' do
    # FIXME: Add OrderStatusHistory records
    it 'gets all order_status_history', focus: true do
      res = @service.order_status_history
      expect(res).to eq(order_status_history_json)
      expect(res['entries']).not_to be_empty
    end

    # FIXME: No record to test against
    it 'gets product WHERE osh_id=1', focus: true do
      res, entry = test_entry(osh_id: 1)
      expect(res).to eq(entry)
    end

    # FIXME: No record to test against
    it 'gets product WHERE osh_id=2', focus: true do
      res = @service.order_status_history(osh_id: 8)
      expect(res).to eq(order_status_history_json['entries'][1])
    end

    # FIXME: No record to test against
    it 'gets product WHERE osh_id=3', focus: true do
      res = @service.order_status_history(osh_id: 9)
      expect(res).to eq(order_status_history_json['entries'][2])
    end
  end

  def find_entry(osh_id)
    order_status_history_json['entries'].find { |e| e['osh_id'] == osh_id }
  end

  def test_entry(osh_id:)
    res = @service.order_status_history(osh_id:)
    entry = find_entry(osh_id)
    [res, entry]
  end
end
