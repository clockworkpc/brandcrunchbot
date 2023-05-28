require 'uri'
require 'net/http'

class GodaddyApi
  def initialize
    @base_url = 'GdAuctionsBiddingWSAPI_v2'
  end

  def request_body(domain_name:)
    template = File.read('app/services/godaddy_request_body_template.xml')
    template.sub('DOMAIN_NAME', domain_name).strip
  end

  def new_soap_request(soap_action_name:, domain_name:)
    url = URI('https://auctions.godaddy.com/gdAuctionsWSAPI/gdAuctionsBiddingWS_v2.asmx')
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    soap_action = "#{@base_url}/#{soap_action_name}"
    request_body = request_body(domain_name:)

    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'text/xml; charset=utf-8'
    request['SOAPAction'] = soap_action
    request['Authorization'] = 'sso-key 31vUUKp41s_Rfiq1XbkwtaRhyF4zcKFtf:P57BU9xsfQTAKk9ZhsWuHk'
    request.body = request_body
    [https, request]
  end

  def parse_response(response)
    doc = Nokogiri::XML(response.body)
    doc.at_xpath('//soap:Body').child.child.child.text.scan(/[A-Za-z0-9]+=".*"/).first.split('" ').map do |kv|
      kv.delete('"').split('=')
    end.to_h
  end

  def get_auction_details(domain_name:)
    soap_action_name = 'GetAuctionDetailsByDomainName'
    domain_name = 'maby.com'
    https, request = new_soap_request(soap_action_name:, domain_name:)
    response = https.request(request)
    puts response.read_body
    parse_response(response)
  end
end
