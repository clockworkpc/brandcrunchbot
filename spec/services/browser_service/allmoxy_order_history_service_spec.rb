require 'rails_helper'

RSpec.describe BrowserService::AllmoxyOrderHistoryService do
  let(:order_number) { 85_636 }
  let(:order_numbers) { [ 85_636 ] }
  let(:first_datetime) do
    datetime_str = '11/08/22 06:53 AM-8'
    pst_notation = '%m/%d/%y %I:%M %p%z'
    DateTime
      .strptime(datetime_str, pst_notation)
      .in_time_zone('America/Los_Angeles')
  end

  let(:order_history_hsh_ary) do
    [{ allmoxy_user: 'PDI Shipping', status: 'Shipped', datetime: '11/08/22 06:53 AM' },
     { allmoxy_user: 'PDI Shipping', status: 'Completed', datetime: '11/08/22 06:53 AM' },
     { allmoxy_user: 'PDI Shipping', status: 'In Progress', datetime: '11/08/22 06:53 AM' },
     { allmoxy_user: 'PDI Shipping', status: 'Verified', datetime: '11/08/22 06:53 AM' },
     { allmoxy_user: 'PDI Shipping', status: 'Ordered', datetime: '11/08/22 06:53 AM' },
     { allmoxy_user: 'PDI Shipping', status: 'Bid', datetime: '11/08/22 06:53 AM' }]
  end

  let(:statuses) { ['Shipped', 'Completed', 'In Progress', 'Verified', 'Ordered', 'Bid'].sort }

  let(:completed_datetime) { DateTime.parse('2022-11-08T06:53:00.000-08:00') }

  describe 'Without logging in' do
  end

  describe 'With Allmoxy login' do
    before(:all) do
      # customer = create(:customer)
      # create(:order, customer:, order_number: 83_331)
      @browser = Utils.watir_browser
      @service = described_class.new(@browser)
      @order_sync_record = create(:order_sync_record,
                                  earliest_ship_date: '2023-01-07')
    end

    after(:all) { @browser.close }

    it 'gets two sets of orders', focus: false do
      res = @service.update_order_history_sheet
    end

    it 'updates the order history sheet', focus: true do
      order_numbers = [
        85_548,
        82_328,
        82_722,
        84_008,
        84_235,
        84_325,
        85_529,
        85_552,
        85_570,
        85_571
      ]
      res = @service.update_order_history_sheet(order_numbers:)
    end
  end

  describe 'old' do
    it 'returns the order history as a Hash', focus: false do
      order_number = 80_167
      res = @service.download_order_history(order_number:)
      expect(res).to be_a(Array)
      res.each do |e|
        expect(e).to be_a(Hash)
        expect(e[:allmoxy_user]).to eq('PDI Shipping')
        expect(e[:status]).not_to be_nil
        expect(e[:datetime]).to be_a(ActiveSupport::TimeWithZone)
      end

      au = res.pluck(:allmoxy_user).uniq.first
      res_statuses = res.pluck(:status).sort
      dt = res.first[:datetime]

      expect(au).to eq('PDI Shipping')
      expect(res_statuses).to eq(statuses)
      expect(dt).to eq(first_datetime)
    end

    it 'updates the status history', focus: false do
      status_history_hsh_ary = @service.download_order_history(order_number:)
      @service.save_order_status_history(order_number:, status_history_hsh_ary:)
      order = Order.find_by(order_number:)
      expect(order.status_history_completed[:datetime]).to be_a(DateTime)
      expect(order.status_history_completed_at).to eq(completed_datetime)
    end
  end
end
