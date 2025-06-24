require 'rails_helper'

RSpec.describe FiftyDollarBinBot, type: :job do
  let(:auction) { create(:auction, domain_name: 'slow-example.com') }
  let(:gda) { instance_double(GodaddyApi) }
  let(:bot) { stubbed_bot.new }

  let(:stubbed_bot) do
    Class.new(FiftyDollarBinBot) do
      attr_accessor :time_ref

      def sleep(seconds)
        time_ref.value += seconds
      end
    end
  end

  before do
    allow(GodaddyApi).to receive(:new).and_return(gda)

    start_time = Time.zone.now
    @time_ref = Struct.new(:value).new(start_time)

    allow(Time).to(receive(:now).and_wrap_original { |_method| @time_ref.value })

    bot.time_ref = @time_ref
  end

  it 'successfully purchases after 150 minutes of polling' do
    attempts_before_success = (150 * 60) / 5
    attempt_counter = 0

    allow(gda).to receive(:get_auction_details) do
      attempt_counter += 1
      if attempt_counter >= attempts_before_success
        { 'IsValid' => 'True', 'Price' => 50 }
      else
        { 'IsValid' => 'False', 'Price' => nil }
      end
    end

    allow(gda).to receive_messages(
      estimate_closeout_domain_price: {
        result: 'Success',
        closeout_domain_price_key: 'abc123'
      },
      instant_purchase_closeout_domain: double(body: File.read('spec/fixtures/slow-example-instantpurchasecloseoutdomain.xml'))
    )

    stub_const("#{described_class}::MAX_ATTEMPTS", attempts_before_success + 5)
    bot.perform(auction)

    auction.reload
    expect(auction.purchase_status).to eq('purchased')
    expect(attempt_counter).to be >= attempts_before_success
  end
end
