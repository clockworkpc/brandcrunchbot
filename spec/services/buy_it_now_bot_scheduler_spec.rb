# frozen_string_literal: true

require 'rails_helper'
require 'timecop'

RSpec.describe BuyItNowBotScheduler, type: :service do
  subject(:scheduler) { described_class.new }

  let(:gsa_double) { instance_double(GoogleSheetsApi) }
  let(:gda_double) { instance_double(GodaddyApi, get_auction_details: {}) }
  let(:bb_double)  { instance_double(BuyItNowBot) }

  before do
    allow(GoogleSheetsApi).to receive(:new).and_return(gsa_double)
    allow(GodaddyApi).to receive(:new).and_return(gda_double)
    allow(BuyItNowBot).to receive(:new).and_return(bb_double)
  end

  describe '#update_active_auctions' do
    context 'when changes is blank' do
      it 'does nothing' do
        expect { scheduler.update_active_auctions(changes: []) }.not_to change(Auction, :count)
      end
    end

    context 'with new auction data' do
      let(:changes) { [{ 'domain_name' => 'example.com', 'bin_price' => 100 }] }

      it 'creates and activates a new auction' do
        expect { scheduler.update_active_auctions(changes: changes) }
          .to change(Auction, :count).by(1)

        auction = Auction.last
        expect(auction).to have_attributes(
          domain_name: 'example.com',
          bin_price: 100,
          active: true
        )
      end
    end
  end

  context 'with existing auction data' do
    let(:domain_name) { Faker::Internet.domain_name }
    let!(:existing) do
      # create the existing record in the database before the example runs
      Auction.create!(
        domain_name: domain_name,
        bin_price: 50,
        active: false
      )
    end

    let(:changes) do
      # your scheduler expects an array of hashes
      [{ 'domain_name' => domain_name, 'bin_price' => 150 }]
    end

    it 'updates and activates existing auction without changing count' do
      # no new records
      expect do
        scheduler.update_active_auctions(changes: changes)
      end.not_to change(Auction, :count)

      existing.reload # pull the latest values from the DB
      expect(existing.bin_price).to eq 150
      expect(existing.active).to be true
    end
  end

  describe '#deactivate_passe_auctions' do
    let!(:a) { Auction.create!(domain_name: 'a.com', active: true, bin_price: 10) }
    let!(:b) { Auction.create!(domain_name: 'b.com', active: true, bin_price: 20) }
    let!(:c) { Auction.create!(domain_name: 'c.com', active: true, bin_price: 30) }

    it 'deactivates auctions not in spreadsheet values' do
      values = [['a.com'], ['c.com']]
      scheduler.deactivate_passe_auctions(values:)
      puts("Auction.count: #{Auction.count}")

      expect(a.reload.active).to be true
      expect(b.reload.active).to be false
      expect(c.reload.active).to be true
    end
  end

  describe '#convert_to_utc' do
    let(:utc_time) { Time.utc(2025, 6, 11, 12, 0, 0) }

    it 'calls Utils.convert_to_utc with the AuctionEndTime string' do
      res = { 'AuctionEndTime' => '01/01/2025 10:00 AM PDT' }
      allow(Utils).to receive(:convert_to_utc).with(datetime_str: res['AuctionEndTime']).and_return(utc_time)

      expect(scheduler.convert_to_utc(res:)).to eq utc_time
    end

    it 'returns nil if no AuctionEndTime present' do
      expect(scheduler.convert_to_utc(res: {})).to be_nil
    end
  end

  describe '#fetch_auction_details' do
    let(:domain_name) { Faker::Internet.domain_name }

    let!(:auction) do
      Auction.create!(
        domain_name:,
        is_valid: false,
        auction_end_time: nil,
        price: nil
      )
    end

    context 'when API returns valid data' do
      subject(:scheduler) { described_class.new(gda: gda_double) }

      let(:gda_double) { instance_double(GodaddyApi, get_auction_details: res) }

      let(:res) do
        {
          'IsValid' => 'true',
          'AuctionEndTime' => '01/01/2025 10:00 AM PDT',
          'Price' => '$123'
        }
      end

      let(:parsed_time) { DateTime.new(2025, 1, 1, 10, 0, 0) }

      before do
        allow(gda_double)
          .to receive(:get_auction_details)
            .with(domain_name: 'foo.com')
            .and_return(res)
        allow(Utils)
          .to receive(:convert_to_utc)
            .and_return(parsed_time)
      end

      it 'updates auction attributes and returns the record' do
        updated = scheduler.fetch_auction_details(auction:)

        expect(updated.is_valid).to be true
        expect(updated.auction_end_time).to eq parsed_time
        expect(updated.price).to eq 123
      end
    end

    context 'when API returns invalid data' do
      let(:res) { { 'IsValid' => 'false' } }

      before do
        allow(gda_double)
          .to receive(:get_auction_details)
            .with(domain_name:)
            .and_return(res)
      end

      it 'marks auction as invalid without setting time or price' do
        updated = scheduler.fetch_auction_details(auction:)

        expect(updated.is_valid).to be false
        expect(updated.auction_end_time).to be_nil
        expect(updated.price).to be_nil
      end
    end
  end

  describe '#schedule_buy_it_now_bot' do
    let(:auction) { instance_double(Auction, auction_end_time: DateTime.new(2025, 6, 11, 12, 0, 0)) }
    let(:job_double) { instance_double('ActiveJob::ScheduledTask', perform_later: true) }

    before do
      allow(BuyItNowBot).to receive(:set).and_return(job_double)
    end

    it 'schedules the BuyItNowBot to run 10 seconds before end time' do
      auction_time = auction.auction_end_time

      scheduler.schedule_buy_it_now_bot(auction: auction, auction_end_time: auction_time)

      expect(BuyItNowBot).to have_received(:set).with(wait_until: auction_time - 10.seconds)
      expect(job_double).to have_received(:perform_later).with(auction, auction_time)
    end
  end

  describe '#schedule_job' do
    subject(:scheduler) { described_class.new }

    let(:auction) { instance_double(Auction, domain_name: 'foo.com', is_valid: is_valid, auction_end_time: dt) }
    let(:dt)      { DateTime.new(2025, 6, 11, 12, 0, 0) }

    before do
      allow(scheduler).to receive(:fetch_auction_details).and_return(updated)
      allow(scheduler).to receive(:schedule_buy_it_now_bot)
      Delayed::Job.delete_all
    end

    context 'when auction is not valid' do
      let(:is_valid) { false }
      let(:updated)  { nil }

      it 'does nothing' do
        scheduler.schedule_job(auction: auction)
        expect(scheduler).not_to have_received(:fetch_auction_details)
        expect(scheduler).not_to have_received(:schedule_buy_it_now_bot)
      end
    end

    context 'when updated auction is invalid' do
      let(:is_valid) { true }
      let(:updated)  { instance_double(Auction, is_valid: false) }

      it 'fetches details but does not schedule' do
        scheduler.schedule_job(auction: auction)
        expect(scheduler).to have_received(:fetch_auction_details).with(auction: auction)
        expect(scheduler).not_to have_received(:schedule_buy_it_now_bot)
      end
    end

    context 'when updated auction is valid and no job exists' do
      let(:is_valid) { true }
      let(:updated)  { instance_double(Auction, domain_name: 'foo.com', is_valid: true, auction_end_time: dt) }

      it 'schedules a new job' do
        scheduler.schedule_job(auction: auction)
        expect(scheduler).to have_received(:schedule_buy_it_now_bot).with(auction: updated, auction_end_time: dt)
      end
    end

    context 'when a job already exists' do
      let(:is_valid) { true }
      let(:updated)  { instance_double(Auction, domain_name: 'foo.com', is_valid: true, auction_end_time: dt) }

      before do
        Delayed::Job.create!(handler: '--- !ruby/object:Delayed::Job {handler: "foo.com"}', run_at: dt)
      end

      it 'does not schedule another job' do
        scheduler.schedule_job(auction: auction)
        expect(scheduler).not_to have_received(:schedule_buy_it_now_bot)
      end
    end
  end

  describe '#call' do
    let!(:old_auction) { Auction.create!(domain_name: 'old.com', bin_price: 5, active: true) }
    let(:changes) do
      [
        { 'domain_name' => 'new1.com', 'bin_price' => 10 },
        { 'domain_name' => 'new2.com', 'bin_price' => 20 }
      ]
    end

    before do
      # stub out sleep to speed tests
      allow(Kernel).to receive(:sleep)
      # seed a stray job so we can verify it’s cleared
      Delayed::Job.create!(handler: 'garbage', run_at: 1.day.ago)
    end

    it 'resets jobs and auctions, updates and schedules' do
      expect(scheduler).to receive(:schedule_job).twice

      scheduler.call(changes: changes)

      expect(Delayed::Job.count).to eq 0
      expect(old_auction.reload.active).to be false

      names = Auction.where(active: true).pluck(:domain_name)
      expect(names).to match_array(%w[new1.com new2.com])
    end
  end
end
