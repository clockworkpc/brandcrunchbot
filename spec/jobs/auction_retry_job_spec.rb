require 'rails_helper'

RSpec.describe AuctionRetryJob, type: :job do
  let(:gda_double) { instance_double(GodaddyApi) }
  let(:gsa_double) { instance_double(GoogleSheetsApi) }
  let(:scheduler_double) { instance_double(BuyItNowBotScheduler) }

  before do
    allow(GodaddyApi).to receive(:new).and_return(gda_double)
    allow(GoogleSheetsApi).to receive(:new).and_return(gsa_double)
  end

  describe '#perform' do
    context 'when no invalid auctions exist' do
      it 'reschedules itself without processing' do
        expect(AuctionRetryJob).to receive(:set).with(wait: 1.hour).and_return(double(perform_later: true))

        AuctionRetryJob.new.perform
      end
    end

    context 'with invalid auctions needing check' do
      let!(:auction) do
        create(:auction,
          domain_name: 'test.com',
          active: true,
          is_valid: false,
          first_checked_at: 2.hours.ago,
          last_checked_at: 2.hours.ago
        )
      end

      before do
        allow(gda_double).to receive(:get_auction_details_by_domain_name).and_return({ 'IsValid' => 'False' })
        allow(AuctionRetryJob).to receive(:set).and_return(double(perform_later: true))
      end

      it 'checks the auction and updates last_checked_at' do
        expect {
          AuctionRetryJob.new.perform
        }.to change { auction.reload.last_checked_at }
      end
    end

    context 'when auction becomes valid' do
      let!(:auction) do
        create(:auction,
          domain_name: 'valid.com',
          active: true,
          is_valid: false,
          first_checked_at: 1.hour.ago,
          last_checked_at: 1.hour.ago,
          bin_price: 25
        )
      end

      let(:valid_response) do
        {
          'IsValid' => 'True',
          'Price' => '$25',
          'AuctionEndTime' => '12/26/2025 02:00 PM (PST)'
        }
      end

      before do
        allow(gda_double).to receive(:get_auction_details_by_domain_name).and_return(valid_response)
        allow(Utils).to receive(:convert_to_utc).and_return(DateTime.new(2025, 12, 26, 22, 0, 0))
        allow(AuctionRetryJob).to receive(:set).and_return(double(perform_later: true))
        allow(BuyItNowBotScheduler).to receive(:new).and_return(scheduler_double)
        allow(scheduler_double).to receive(:schedule_job)
      end

      it 'marks auction as valid and schedules BuyItNowBot' do
        expect(scheduler_double).to receive(:schedule_job).with(auction: auction)

        AuctionRetryJob.new.perform

        auction.reload
        expect(auction.is_valid).to be true
        expect(auction.price).to eq 25
      end
    end

    context 'when auction becomes valid with high price' do
      let!(:auction) do
        create(:auction,
          domain_name: 'expensive.com',
          active: true,
          is_valid: false,
          first_checked_at: 1.hour.ago,
          last_checked_at: 1.hour.ago,
          bin_price: 75
        )
      end

      let(:valid_response) do
        {
          'IsValid' => 'True',
          'Price' => '$75',
          'AuctionEndTime' => '12/26/2025 02:00 PM (PST)'
        }
      end

      before do
        allow(gda_double).to receive(:get_auction_details_by_domain_name).and_return(valid_response)
        allow(Utils).to receive(:convert_to_utc).and_return(DateTime.new(2025, 12, 26, 22, 0, 0))
        allow(AuctionRetryJob).to receive(:set).and_return(double(perform_later: true))
        allow(BuyItNowBotScheduler).to receive(:new).and_return(scheduler_double)
        allow(scheduler_double).to receive(:schedule_job)
      end

      it 'schedules FiftyDollarBinBot for high price auctions' do
        expect(scheduler_double).to receive(:schedule_job).with(auction: auction)

        AuctionRetryJob.new.perform

        auction.reload
        expect(auction.is_valid).to be true
        expect(auction.price).to eq 75
      end
    end
  end

  describe '#should_check_auction?' do
    subject { AuctionRetryJob.new }

    context 'auction less than 24 hours old' do
      let(:auction) do
        create(:auction,
          created_at: 5.hours.ago,
          first_checked_at: 5.hours.ago,
          last_checked_at: 30.minutes.ago
        )
      end

      it 'does not check if last checked less than 1 hour ago' do
        expect(subject.send(:should_check_auction?, auction)).to be false
      end

      it 'checks if last checked more than 1 hour ago' do
        auction.update!(last_checked_at: 61.minutes.ago)
        expect(subject.send(:should_check_auction?, auction)).to be true
      end
    end

    context 'auction more than 24 hours old' do
      let(:auction) do
        create(:auction,
          created_at: 3.days.ago,
          first_checked_at: 3.days.ago,
          last_checked_at: 12.hours.ago
        )
      end

      it 'does not check if last checked less than 24 hours ago' do
        expect(subject.send(:should_check_auction?, auction)).to be false
      end

      it 'checks if last checked more than 24 hours ago' do
        auction.update!(last_checked_at: 25.hours.ago)
        expect(subject.send(:should_check_auction?, auction)).to be true
      end
    end

    context 'auction never checked before' do
      let(:auction) do
        create(:auction,
          created_at: 1.day.ago,
          first_checked_at: 1.day.ago,
          last_checked_at: nil
        )
      end

      it 'checks the auction' do
        expect(subject.send(:should_check_auction?, auction)).to be true
      end
    end
  end

  describe '#auctions_to_check' do
    subject { AuctionRetryJob.new }

    let!(:invalid_active_auction) do
      create(:auction, active: true, is_valid: false, first_checked_at: 1.hour.ago)
    end

    let!(:valid_auction) do
      create(:auction, active: true, is_valid: true, first_checked_at: 1.hour.ago)
    end

    let!(:inactive_invalid_auction) do
      create(:auction, active: false, is_valid: false, first_checked_at: 1.hour.ago)
    end

    let!(:never_checked_auction) do
      create(:auction, active: true, is_valid: false, first_checked_at: nil)
    end

    it 'only includes active, invalid auctions that have been checked before' do
      auctions = subject.send(:auctions_to_check)
      expect(auctions).to include(invalid_active_auction)
      expect(auctions).not_to include(valid_auction)
      expect(auctions).not_to include(inactive_invalid_auction)
      expect(auctions).not_to include(never_checked_auction)
    end
  end

  describe 'error handling' do
    let!(:auction) do
      create(:auction,
        domain_name: 'error.com',
        active: true,
        is_valid: false,
        first_checked_at: 2.hours.ago,
        last_checked_at: 2.hours.ago
      )
    end

    before do
      allow(gda_double).to receive(:get_auction_details_by_domain_name).and_raise(StandardError, 'API Error')
      allow(AuctionRetryJob).to receive(:set).and_return(double(perform_later: true))
    end

    it 'handles errors gracefully and continues rescheduling' do
      expect(Rails.logger).to receive(:error).with(/Error checking auction error.com/)
      expect(AuctionRetryJob).to receive(:set).with(wait: 1.hour)

      expect {
        AuctionRetryJob.new.perform
      }.not_to raise_error
    end
  end
end
