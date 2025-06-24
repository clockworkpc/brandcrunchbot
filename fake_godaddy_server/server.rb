require 'sinatra/base'
require 'rack/throttle'

class FakeGodaddyServer < Sinatra::Base
  use Rack::Throttle::Minute, max: 60

  set :port, 4567
  set :bind, '0.0.0.0'

  @start_time = Time.now

  get '/' do
    content_type :html  # 👈 this tells Sinatra to render the response as HTML

    <<~HTML
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Hello Sinatra</title>
        <style>
        body {
          background: #1e1e2f;
          color: #fefefe;
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          margin: 0;
        }
        .hello-box {
          background: #2d2d44;
          padding: 2rem 3rem;
          border-radius: 10px;
          box-shadow: 0 0 20px rgba(0,0,0,0.5);
          text-align: center;
        }
        h1 {
          margin: 0;
          font-size: 2.5rem;
        }
        </style>
      </head>
      <body>
        <div class="hello-box">
          <h1>Hello, Markus.  This a dummy server 👋</h1>
        </div>
      </body>
    </html>
    HTML
  end


  get '/auction/:domain' do
    delay = (ENV['SIMULATED_AVAILABILITY_DELAY'] || 300).to_i
    if (Time.now - @start_time) >= delay
      content_type :json
      { IsValid: 'True', Price: 50 }.to_json
    else
      status 404
      { IsValid: 'False' }.to_json
    end
  end

  get '/estimate_closeout_domain_price/:domain' do
    content_type :json
    { result: 'Success', closeout_domain_price_key: 'abc123' }.to_json
  end

  post '/instant_purchase_closeout_domain/:domain' do
    content_type :xml
    <<~XML
    <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ns="GdAuctionsBiddingWSAPI_v2">
    <soap:Body>
    <ns:InstantPurchaseCloseoutDomainResponse>
    <ns:InstantPurchaseCloseoutDomainResult>
    <![CDATA[
    <InstantPurchaseCloseoutDomain Result="Success" Domain="#{params['domain']}" />
    ]]>
    </ns:InstantPurchaseCloseoutDomainResult>
    </ns:InstantPurchaseCloseoutDomainResponse>
    </soap:Body>
    </soap:Envelope>
    XML
  end

  post '/gdAuctionsWSAPI/gdAuctionsBiddingWS_v2.asmx' do
    body = request.body.read
    if body.include?('GetAuctionDetails')
      # return a fake auction response
    elsif body.include?('EstimateCloseoutDomainPrice')
      # return fake estimate response
    elsif body.include?('InstantPurchaseCloseoutDomain')
      # return fake purchase confirmation
    end
  end
end

FakeGodaddyServer.run!
