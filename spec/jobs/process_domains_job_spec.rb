require 'rails_helper'

RSpec.describe ProcessDomainsJob, type: :job do
  let(:changes) { { 'C1' => 'example.com', 'C2' => '' } }
  let(:ga_double) { instance_double(GodaddyApi) }

  before do
    allow(GodaddyApi).to receive(:new).and_return(ga_double)
    allow(ga_double).to receive(:get_auction_details).with(domain_name: 'example.com').and_return({
      'AuctionEndTime' => '2025-12-31 23:59:59'
    })
    allow(PerformAuctionJob).to receive(:set).and_return(PerformAuctionJob)
    allow(PerformAuctionJob).to receive(:perform_later)
  end

  it 'schedules a PerformAuctionJob 5 seconds before the auction end time' do
    expected_run_time = DateTime.parse('2025-12-31 23:59:59') - 5.seconds

    described_class.perform_now(changes)

    expect(PerformAuctionJob).to have_received(:set).with(wait_until: expected_run_time)
    expect(PerformAuctionJob).to have_received(:perform_later).with('example.com')
  end
end

