require 'rails_helper'

RSpec.describe PerformAuctionJob, type: :job do
  let(:domain_name) { 'example.com' }
  let(:s_bid_amount) { '10' }
  let(:ga_double) { instance_double(GodaddyApi) }

  before do
    allow(GodaddyApi).to receive(:new).and_return(ga_double)
  end

  it 'stops when the response is "foo"' do
    allow(ga_double).to receive(:place_bid_or_purchase).with(domain_name:, s_bid_amount:).and_return('foo')

    expect do
      described_class.perform_now(domain_name, s_bid_amount)
    end.not_to raise_error
  end

  it 'retries up to 10 times if response is not "foo"' do
    call_count = 0
    allow(ga_double).to receive(:place_bid_or_purchase) do
      call_count += 1
      'not_foo'
    end

    allow_any_instance_of(described_class).to receive(:sleep) # disable sleep delay in test

    described_class.perform_now(domain_name, s_bid_amount)
    expect(call_count).to eq(10)
  end
end
