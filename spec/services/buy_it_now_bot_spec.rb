require 'rails_helper'

# rubocop:disable Rspec/MultipleMemoizedHelpers, Rspec/MultipleExpectations, Rspec/ExampleLength
describe BuyItNowBot, type: :job do
  let(:bot) { described_class.new }
  let(:auction) { create(:auction) }
  let(:domain) { auction.domain_name }
  let(:valid_time) { DateTime.new(2025, 1, 1, 10, 0, 0) }

  describe '#purchase_outright' do
    let(:job) { described_class.new }
    let(:gda) { instance_double(GodaddyApi) }

    before do
      allow(job).to receive(:gda).and_return(gda)
    end

    it 'returns success after a valid auction and closeout' do
      allow(gda).to receive_messages(
        get_auction_details: { 'IsValid' => 'True', 'Price' => '10.0' },
        estimate_closeout_domain_price: { result: 'Success', closeout_domain_price_key: 'abc123' },
        instant_purchase_closeout_domain: nil # Assuming no specific return value is needed
      )

      result = job.purchase_outright(domain_name: 'example.com', attempts_per_second: 2, total_attempts: 2)

      expect(result[:success]).to be true
    end

    it 'returns failure if no valid attempts succeed' do
      allow(gda).to receive(:get_auction_details).and_return({ 'IsValid' => 'False' })

      result = job.purchase_outright(domain_name: 'bad.com', attempts_per_second: 2, total_attempts: 2)

      expect(result[:success]).to be false
      expect(result[:valid]).to be false
    end
  end

  describe '#parse_instant_purchase_response extra' do
    let(:job) { described_class.new }

    context 'with valid SOAP response' do
      let(:xml_body) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
          <soap:Body>
          <ns:EstimateCloseoutDomainPriceResult xmlns:ns="GdAuctionsBiddingWSAPI_v2">
          <Result><![CDATA[
          <InstantPurchaseCloseoutDomain>
          <DomainName>example.com</DomainName>
          <Price>10.99</Price>
          <IsValid>True</IsValid>
          </InstantPurchaseCloseoutDomain>
          ]]></Result>
          </ns:EstimateCloseoutDomainPriceResult>
          </soap:Body>
          </soap:Envelope>
        XML
      end

      let(:response) { instance_double(Net::HTTPResponse, body: xml_body) }

      it 'parses the inner XML and returns expected hash' do
        result = job.parse_instant_purchase_response(response)
        expect(result).to eq({
                               'DomainName' => 'example.com',
                               'Price' => '10.99',
                               'IsValid' => 'True'
                             })
      end
    end

    context 'when response is a failure hash' do
      it 'returns failure result' do
        result = job.parse_instant_purchase_response({ ok: false })
        expect(result).to eq({ 'Result' => 'Failure' })
      end
    end
  end

  describe '#parse_instant_purchase_response' do
    subject { bot.parse_instant_purchase_response(response) }

    context 'when response indicates failure' do
      let(:response) { { ok: false } }

      it { is_expected.to eq('Result' => 'Failure') }
    end

    context 'when response body contains valid XML' do
      let(:xml_body) do
        <<~XML
          <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
          <soap:Body>
          <ns:EstimateCloseoutDomainPriceResult xmlns:ns="GdAuctionsBiddingWSAPI_v2">
          <Result>
          <![CDATA[<InstantPurchaseCloseoutDomain><CloseoutDomainPriceKey>ABC123</CloseoutDomainPriceKey></InstantPurchaseCloseoutDomain>]]>
          </Result>
          </ns:EstimateCloseoutDomainPriceResult>
          </soap:Body>
          </soap:Envelope>
        XML
      end

      # Assuming response is like an HTTP response, e.g., Net::HTTPResponse
      let(:response) { instance_double(Net::HTTPResponse, body: xml_body) }

      it 'extracts the inner hash from the fragment' do
        result = bot.parse_instant_purchase_response(response)
        expect(result).to include('CloseoutDomainPriceKey' => 'ABC123')
      end
    end
  end

  describe '#scheduled_job' do
    subject { bot.scheduled_job(auction) }

    let(:wrapper) do
      double(
        'PerformAuctionJob',
        job_data: { 'arguments' => [{ '_aj_globalid' => auction.to_global_id.to_s }] }
      )
    end
    let(:handler_yaml) { 'dummy-yaml' }
    let(:job_record) { instance_double(Delayed::Job, handler: handler_yaml) }

    before do
      allow(Delayed::Job).to receive(:where).and_return([job_record])
      allow(YAML).to receive(:unsafe_load).with(handler_yaml).and_return(wrapper)
    end

    it 'returns the matching job record' do
      expect(subject).to eq(job_record)
    end
  end

  describe '#check_auction' do
    subject { bot.check_auction(auction_details: details) }

    context 'when IsValid is False' do
      let(:details) { { 'IsValid' => 'False', 'Price' => '$1' } }

      it { is_expected.to include(valid: false) }
    end

    context 'when Price is nil' do
      let(:details) { { 'IsValid' => 'True', 'Price' => nil } }

      it { is_expected.to include(valid: false) }
    end

    context 'when details are valid' do
      let(:details) { { 'IsValid' => 'True', 'Price' => '$5' } }

      it { is_expected.to eq(valid: true, rescheduled: false, success: false) }
    end
  end

  describe '#purchase_outright extra' do
    let(:attempts) { 2 }
    let(:price_hash) { { result: 'Success', closeout_domain_price_key: 'XYZ' } }

    before do
      allow(bot).to receive(:sleep)
      allow(bot).to receive(:gda).and_return(
        instance_double(GodaddyApi,
          get_auction_details: { 'IsValid' => 'True', 'Price' => '$10' },
          estimate_closeout_domain_price: price_hash,
          instant_purchase_closeout_domain: nil)
      )
    end

    it 'returns success true if purchase succeeds' do
      result = bot.purchase_outright(domain_name: domain, attempts_per_second: 1, total_attempts: attempts)
      expect(result[:success]).to be true
    end

    it 'returns valid false if auction never becomes valid' do
      allow(bot).to receive(:gda).and_return(
        instance_double(GodaddyApi, get_auction_details: { 'IsValid' => 'False' })
      )
      result = bot.purchase_outright(domain_name: domain, attempts_per_second: 1, total_attempts: attempts)
      expect(result[:valid]).to be false
    end
  end

  describe '#preliminary_validation' do
    before do
      allow(bot).to receive(:count_down_until)
      allow(bot).to receive(:gda).and_return(
        instance_double(GodaddyApi, get_auction_details: { 'IsValid' => 'True', 'AuctionEndTime' => '01/01/2025 10:00 AM PDT', 'Price' => '$20' })
      )
      allow(Utils).to receive(:convert_to_utc).and_return(valid_time)
    end

    it 'invokes count_down_until with converted end time' do
      bot.preliminary_validation(domain_name: domain)

      expect(bot).to have_received(:count_down_until).with(
        domain_name: domain,
        auction_end_time: valid_time + ENV.fetch('BUY_IT_NOW_BOT_DELAY', 0.4).to_f,
        secs_f: ENV.fetch('BUY_IT_NOW_SLEEP', 1).to_f
      )
    end
  end
end
# rubocop:enable Rspec/MultipleMemoizedHelpers, Rspec/MultipleExpectations, Rspec/ExampleLength
