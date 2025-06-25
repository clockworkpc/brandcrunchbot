require 'rails_helper'

RSpec.describe FiftyDollarBinBot, type: :job do
  let(:auction) { create(:auction, domain_name: 'example.com') }
  let(:gda) { instance_double(GodaddyApi) }

  before do
    allow(GodaddyApi).to receive(:new).and_return(gda)
  end

  it 'marks purchase_status as purchased if success' do
    allow(gda).to receive(:get_auction_details).and_return({ 'IsValid' => 'True', 'Price' => 50 })
    allow(gda).to receive(:estimate_closeout_domain_price).and_return({ result: 'Success', closeout_domain_price_key: 'abc123' })

    allow(gda).to receive(:instant_purchase_closeout_domain).and_return(
      double(body: <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ns="GdAuctionsBiddingWSAPI_v2">
          <soap:Body>
            <ns:InstantPurchaseCloseoutDomainResponse>
              <ns:InstantPurchaseCloseoutDomainResult>
                <![CDATA[
                  <InstantPurchaseCloseoutDomain Result="Success" Domain="example.com" Price="25" RenewalPrice="20" Total="45.18" OrderID="987654321" />
                ]]>
              </ns:InstantPurchaseCloseoutDomainResult>
            </ns:InstantPurchaseCloseoutDomainResponse>
          </soap:Body>
        </soap:Envelope>
      XML
            )
    )

    perform_enqueued_jobs do
      described_class.perform_later(auction)
    end

    auction.reload
    expect(auction.purchase_status).to eq('purchased')
  end
end
