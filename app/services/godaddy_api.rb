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
    auction_details = parse_auction_details(response)
    Rails.logger.info(auction_details)
    auction_details
  end

  def parse_estimate_closeout_domain_price(response)
    doc = Nokogiri::XML(response.body)

    Rails.logger.info(response.body)

    namespaces = {
      'soap' => 'http://www.w3.org/2003/05/soap-envelope',
      'ns' => 'GdAuctionsBiddingWSAPI_v2'
    }

    response_node = doc.xpath('//ns:EstimateCloseoutDomainPriceResult', namespaces)
    return unless response_node

    xml_fragment = response_node.first.children.first.text
    parsed_fragment = Nokogiri::XML(xml_fragment)

    result = {
      result: parsed_fragment.at_xpath('//EstimateCloseoutDomainPrice')['Result'],
      domain: parsed_fragment.at_xpath('//EstimateCloseoutDomainPrice')['Domain'],
      price: parsed_fragment.at_xpath('//EstimateCloseoutDomainPrice')['Price'],
      renewal_price: parsed_fragment.at_xpath('//EstimateCloseoutDomainPrice')['RenewalPrice'],
      icann_fee: parsed_fragment.at_xpath('//EstimateCloseoutDomainPrice')['ICANNFee'],
      taxes: parsed_fragment.at_xpath('//EstimateCloseoutDomainPrice')['Taxes'],
      private_registration: parsed_fragment.at_xpath('//EstimateCloseoutDomainPrice')['PrivateRegistration'],
      total: parsed_fragment.at_xpath('//EstimateCloseoutDomainPrice')['Total'],
      closeout_domain_price_key: parsed_fragment.at_xpath('//EstimateCloseoutDomainPrice')['closeoutDomainPriceKey']
    }

    Rails.logger.info("Closeout Key: #{result[:closeout_domain_price_key]}")
    result
  end

  def estimate_closeout_domain_price(domain_name:)
    soap_action_name = 'EstimateCloseoutDomainPrice'
    basename = 'estimate_closeout_domain_price'
    add_privacy = false
    kwargs = { domain_name:, add_privacy: }
    https, request = new_soap_request(soap_action_name:, basename:, kwargs:)
    response = https.request(request)
    Rails.logger.info("#{domain_name}: #{response.code}")
    Rails.logger.info(response.body)
    return unless response.code.to_i == 200

    parse_estimate_closeout_domain_price(response)
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

  def parse_instant_purchase_closeout_domain(response:)
    Rails.logger.info(response.body)
    doc = Nokogiri::XML(response.body)
    Rails.logger.info(doc)
    result = doc.at_xpath('//InstantPurchaseCloseoutDomainResult')
    Rails.logger.info(result)
    # result = doc.at_xpath('//InstantPurchaseCloseoutDomainResult').content
    # decoded_result = Nokogiri::HTML.fragment(result).to_s
    # decoded_doc = Nokogiri::XML(decoded_result)
    #
    # result = decoded_doc.at_xpath('//InstantPurchaseCloseoutDomain/@Result').value
    # domain = decoded_doc.at_xpath('//InstantPurchaseCloseoutDomain/@Domain').value
    # price = decoded_doc.at_xpath('//InstantPurchaseCloseoutDomain/@Price').value
    # renewal_price = decoded_doc.at_xpath('//InstantPurchaseCloseoutDomain/@RenewalPrice').value
    # total = decoded_doc.at_xpath('//InstantPurchaseCloseoutDomain/@Total').value
    # order_id = decoded_doc.at_xpath('//InstantPurchaseCloseoutDomain/@OrderID').value
    #
    # {
    #   result:,
    #   domain:,
    #   price:,
    #   renewal_price:,
    #   total:,
    #   order_id:
    # }
  end

  def instant_purchase_closeout_domain(domain_name:, closeout_domain_price_key:)
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
    Rails.logger.info(response.body)
    parse_instant_purchase_closeout_domain(response:)
  end

  def purchase_instantly(domain_name:)
    result = { ok: false }
    Rails.logger.info('Requesting EstimateCloseoutDomainPrice')
    cdpr = estimate_closeout_domain_price(domain_name:)
    closeout_domain_price_key = cdpr[:closeout_domain_price_key]
    Rails.logger.info("CDPR Key: #{closeout_domain_price_key}")
    return result unless closeout_domain_price_key

    result = instant_purchase_closeout_domain(domain_name:, closeout_domain_price_key:)
    Rails.logger.info(result.body)
    result
  end
end
