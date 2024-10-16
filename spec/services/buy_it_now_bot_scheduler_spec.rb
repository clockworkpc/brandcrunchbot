require 'rails_helper'

RSpec.describe BuyItNowBotScheduler, type: :model do
  let(:google_sheets_api) { instance_double(GoogleSheetsApi) }
  let(:service) { instance_double('Google::Apis::SheetsV4::SheetsService') }
  let(:godaddy_api) { instance_double(GodaddyApi) }
  let(:buy_it_now_bot) { instance_double(BuyItNowBot) }
  let(:scheduler) { described_class.new }
  let(:sheet_id) { 'test_sheet_id' }
  let(:spreadsheet_response) do
    OpenStruct.new(values: [
                     ['example.com', '100', '500'],
                     ['testdomain.net', '150', '600']
                   ])
  end
  let(:auction_details_response) do
    {
      'isValid' => 'true',
      'AuctionEndTime' => '2024-10-05T10:00:00Z',
      'Price' => '$450'
    }
  end

  before do
    allow(Rails.application.credentials).to receive(:sheet_id).and_return(sheet_id)
    allow(GoogleSheetsApi).to receive(:new).and_return(google_sheets_api)

    # Use class_double for GodaddyApi
    allow(GodaddyApi).to receive(:new).and_return(godaddy_api)

    allow(BuyItNowBot).to receive(:new).and_return(buy_it_now_bot)

    # Mock the internal service used by GoogleSheetsApi
    allow(google_sheets_api).to receive(:get_spreadsheet_values) do |**args|
      args[:spreadsheet_id] = sheet_id
      args[:range] = 'domains!A1:C'
      # expect(args[:spreadsheet_id]).to eq(sheet_id)
      # expect(args[:range]).to eq('domains!A1:C')
      spreadsheet_response
    end

    allow(godaddy_api).to receive(:get_auction_details) do |**args|
      args[:domain_name] = 'example.com'
      auction_details_response
    end
    # .with(domain_name: 'example.com')
    # .and_return(auction_details_response)

    allow(godaddy_api).to receive(:get_auction_details) do |**args|
      args[:domain_name] = 'testdomain.net'
      auction_details_response
    end

    # allow(godaddy_api).to receive(:get_auction_details)
    #   .with(domain_name: 'testdomain.net')
    #   .and_return(auction_details_response)

    allow(buy_it_now_bot).to receive(:delay).and_return(buy_it_now_bot)
    allow(buy_it_now_bot).to receive(:call)
  end

  describe '#call' do
    it 'retrieves domains from Google Sheets and schedules BuyItNowBot' do
      auction1 = Auction.create!(domain_name: 'example.com', proxy_bid: 100, bin_price: 500, active: true)
      auction2 = Auction.create!(domain_name: 'testdomain.net', proxy_bid: 150, bin_price: 600, active: true)

      expect(service).to receive(:get_spreadsheet_values)
        .with(sheet_id, 'domains!A1:C')

      expect(godaddy_api).to receive(:get_auction_details)
        .with(domain_name: 'example.com')

      expect(godaddy_api).to receive(:get_auction_details)
        .with(domain_name: 'testdomain.net')

      expect(buy_it_now_bot).to receive(:call)
        .with(domain_name: 'example.com', target_price: 500)

      expect(buy_it_now_bot).to receive(:call)
        .with(domain_name: 'testdomain.net', target_price: 600)

      scheduler.call

      auction1.reload
      auction2.reload

      expect(auction1.auction_end_time).to eq(DateTime.parse('2024-10-05T10:00:00Z'))
      expect(auction2.auction_end_time).to eq(DateTime.parse('2024-10-05T10:00:00Z'))
    end
  end
end
