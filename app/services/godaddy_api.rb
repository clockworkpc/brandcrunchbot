require 'uri'
require 'net/http'

class GodaddyApi
  def initialize
    @base_url = 'GdAuctionsBiddingWSAPI_v2'
  end

  def get_auction_details_by_domain_name(domain_name:)
    soap_action_name = 'GetAuctionDetailsByDomainName'
    basename = 'get_auction_details_by_domain_name'
    kwargs = { domain_name: }
    https, request = new_soap_request(soap_action_name:, basename:, kwargs:)

    response = https.request(request)
    parse_auction_details(response)
  end

  def get_auction_details(domain_name:)
    soap_action_name = 'GetAuctionDetails'
    basename = 'get_auction_details'
    kwargs = { domain_name: }
    https, request = new_soap_request(soap_action_name:, basename:, kwargs:)
    response = https.request(request)
    parse_auction_details(response)
  end

  def get_auction_list(page_number:, rows_per_page:, begins_with_keyword:)
    soap_action_name = 'GetAuctionList'
    basename = 'get_auction_list'
    kwargs = { page_number:, rows_per_page:, begins_with_keyword: }
    https, request = new_soap_request(soap_action_name:, basename:, kwargs:)
    response = https.request(request)
    parse_auction_list(response)
  end

  def request_body(basename:, kwargs:)
    filepath = "app/assets/xml_templates/#{basename}.xml"
    template = File.read(filepath)
    kwargs.each do |k, v|
      template.sub!(k.to_s.upcase, v.to_s).strip
    end
    template
  end

  def new_soap_request(soap_action_name:, basename:, kwargs:)
    url = URI('https://auctions.godaddy.com/gdAuctionsWSAPI/gdAuctionsBiddingWS_v2.asmx')
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    soap_action = "#{@base_url}/#{soap_action_name}"
    prod_key = Rails.application.credentials[:prod_key]
    prod_secret = Rails.application.credentials[:prod_secret]

    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'text/xml; charset=utf-8'
    request['SOAPAction'] = soap_action
    request['Authorization'] = "sso-key #{prod_key}:#{prod_secret}"
    request.body = request_body(basename:, kwargs:)
    [https, request]
  end

  def parse_auction_details(response)
    doc = Nokogiri::XML(response.body)
    doc.at_xpath('//soap:Body').child.child.child.text.scan(/[A-Za-z0-9]+=".*"/).first.split('" ').map do |kv|
      kv.delete('"').split('=')
    end.to_h
  end

  def parse_auction_list(response)
    doc = Nokogiri::XML(response.body)
    text = doc.at_xpath('//soap:Body').child.child.child.text
    ary_ary = text
              .sub(/<AuctionList IsValid="True" TotalRecords="\d+">/, '')
              .gsub('Auction ', '').gsub('USD', '').gsub(/(\d+)S/, '\1')
              .gsub('ValuationPrice="-"', 'ValuationPrice=0')
              .gsub(/(\d+),(\d+)/, '\1\2')
              .delete('>"/$')
              .split('<')
              .map(&:split).reject(&:empty?)
    dictionary = ary_ary.map do |ary|
      ary.map do |str|
        str.split('=')
      end
    end

    dictionary.map do |entry|
      entry.to_h do |ary|
        key = ary.first.titleize.parameterize(separator: '_').to_sym
        is_numeric = !Integer(ary[1], exception: false).nil?
        value = is_numeric ? ary[1].to_i : ary[1]
        [key, value]
      end
    end
  end

  def place_bid_or_purchase(domain_name:, s_bid_amount:)
    key = Rails.application.credentials[:ote_key]
    secret = Rails.application.credentials[:ote_secret]

    soap_action_name = 'PlaceBidOrPurchase'
    basename = 'place_bid_or_purchase'
    kwargs = {
      domain_name:,
      s_bid_amount:,
      use_my_purchase_profile: true,
      accept_utos: true,
      accept_ama: true,
      accept_dnra: true,
      bid_comment: domain_name
    }

    https, request = new_soap_request(soap_action_name:, basename:, kwargs:)
    response = https.request(request)
    parse_auction_list(response)
  end

  # TODO: Need to test in OTE if possible
  def instant_purchase_closeout_domain(domain_name:, closeout_domain_price_key:)
    key = Rails.application.credentials[:ote_key]
    secret = Rails.application.credentials[:ote_secret]

    soap_action_name = 'InstantPurchaseCloseoutDomain'
    basename = 'instant_purchase_closeout_domain'
    kwargs = {
      domain_name:,
      closeout_domain_price_key:,
      accept_utos: true,
      accept_ama: true,
      accept_dnra: true
    }

    https, request = new_soap_request(soap_action_name:, basename:, kwargs:)
    response = https.request(request)
    require 'pry'; binding.pry
    parse_auction_list(response)

    # TODO: Ascertain whether OTE credentials can be used
    # TODO: Call on domain that has already been purchased
    # TODO: Test in real time with Markus
    # TODO: Rake task
    # TODO: Schedule rake task in heroku
    # TODO: Add button in UI?

    # POST /gdAuctionsWSAPI/gdAuctionsBiddingWS_v2.asmx HTTP/1.1
    # Host: auctions.godaddy.com
    # Content-Type: application/soap+xml; charset=utf-8
    # Content-Length: length

    # <?xml version="1.0" encoding="utf-8"?>
    # <soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
    # <soap12:Body>
    # <InstantPurchaseCloseoutDomain xmlns="GdAuctionsBiddingWSAPI_v2">
    #   <domainName>string</domainName>
    #   <closeoutDomainPriceKey>string</closeoutDomainPriceKey>
    #   <acceptUTOS>boolean</acceptUTOS>
    #   <acceptAMA>boolean</acceptAMA>
    #   <acceptDNRA>boolean</acceptDNRA>
    # </InstantPurchaseCloseoutDomain>
    # </soap12:Body>
    # </soap12:Envelope>
  end
end
