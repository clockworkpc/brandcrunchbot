require 'rails_helper'

RSpec.describe AllmoxyApiService do
  let(:door_orders_body) do
    {
      name: nil,
      status: {
        verified: 1,
        'in progress': 1
      },
      start_date: '2022-06-18',
      end_date: '2022-07-18',
      tags_any_Order: [
        { caption: 'DoorFinish', value: 85 },
        { caption: 'solid', value: 100 },
        { caption: 'unfinished', value: 86 }
      ]
    }
  end

  describe 'Logging in' do
    # before do
    #   Watir.default_timeout = 2
    #   @browser = Watir::Browser.new(:chrome, headless: true)
    # end

    # after do
    #   @browser.close
    # end

    it 'generates an Orders Report body from params' do
      a = described_class.new('4q2q5dtn65n2m1pv3r0uqfevfo')
      body = door_orders_body
      b = a.orders_report_body(**body)
      expect(b[:'status[verified]']).to eq(body[:status][:verified])
      expect(b[:'status[in progress]']).to eq(body[:status][:'in progress'])
      expect(b[:tags_any_Order].first[:caption]).to eq('DoorFinish')
    end

    # it 'orders report' do
    #   # a = described_class.new(@browser)
    #   a = described_class.new('4q2q5dtn65n2m1pv3r0uqfevfo')
    #   x = a.orders_report_post
    #   y = a.orders_report_csv
    # end
  end
end
