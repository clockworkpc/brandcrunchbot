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
    namespaces = {
      'soap' => 'http://www.w3.org/2003/05/soap-envelope',
      'ns' => 'GdAuctionsBiddingWSAPI_v2'
    }

    Rails.logger.info(response.body)

    doc = Nokogiri::XML(response.body)
    node = doc.at_xpath('//ns:EstimateCloseoutDomainPriceResult', namespaces)
    return {} unless node

    cdata_content = node.text.strip
    parsed = Nokogiri::XML(cdata_content)
    root = parsed.root
    return {} unless root && root.name == 'EstimateCloseoutDomainPrice'

    extract_attribute = ->(key) { root[key] }

    result = {
      result: extract_attribute['Result'],
      domain: extract_attribute['Domain'],
      price: extract_attribute['Price']&.to_i,
      renewal_price: extract_attribute['RenewalPrice'],
      icann_fee: extract_attribute['ICANNFee'],
      taxes: extract_attribute['Taxes'],
      private_registration: extract_attribute['PrivateRegistration'],
      total: extract_attribute['Total'],
      closeout_domain_price_key: extract_attribute['closeoutDomainPriceKey']
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
    return {} unless response.code.to_i == 200

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
    # load and drop all namespaces
    doc = Nokogiri::XML(response.body)
    doc.remove_namespaces!

    # find the CDATA text under GetAuctionDetailsResult
    cdata = doc.at_xpath('//GetAuctionDetailsResult').text

    # parse the fragment and remove namespaces again
    frag = Nokogiri::XML(cdata).remove_namespaces!

    # locate the <AuctionDetails> node
    node = frag.at_xpath('//AuctionDetails')
    return {} unless node

    # build a hash of its attributes
    node.attributes.transform_values(&:value)
  end

  def parse_auction_list(response)
    doc = Nokogiri::XML(response.body)
    doc.remove_namespaces!

    cdata_node = doc.at_xpath('//GetAuctionListResult')
    return [] unless cdata_node

    cdata = cdata_node.text
    return [] if cdata.empty?

    frag = Nokogiri::XML(cdata).remove_namespaces!
    return [] unless frag

    frag.xpath('//Auction').map do |node|
      node.attributes.each_with_object({}) do |(name, attr), h|
        key = name.underscore.to_sym
        value = attr.value
        h[key] = /^\d+$/.match?(value) ? value.to_i : value
      end
    end
  end

  def place_bid_or_purchase(domain_name:, s_bid_amount:)
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
