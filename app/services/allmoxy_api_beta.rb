require 'uri'
require 'net/http'
require 'json_deep_parse'

class AllmoxyApiBeta
  attr_reader :access_token

  def initialize
    @base_url = 'https://auth.allmoxybeta.com'
    @base_api_url = 'https://api.allmoxybeta.com/v2'
    @access_token = access_token_check_or_refresh
  end

  def get_path(method, param = nil)
    param.nil? ? method : "#{method}/#{param}"
  end

  def get_response(path:)
    https, request = get_request(path:)
    response = https.request(request)
    JSON.parse(response.body)
  end

  def endpoint_path(sym)
    sym.to_s.split('_').join('-')
  end

  def post_response(path:, body:)
    https, request = post_request(path:, body:)
    response = https.request(request)
    JSON.dump(response.body)
  end

  private

  def access_token_request
    uri = [
      "#{@base_url}/oauth2/token?grant_type=client_credentials",
      "client_id=#{Rails.application.credentials[:allmoxy_api_beta_client_id]}",
      "client_secret=#{Rails.application.credentials[:allmoxy_api_beta_client_secret]}"
    ].join('&')

    url = URI(uri)

    https = Net::HTTP.new(url.host, url.port);
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/x-www-form-urlencoded'

    [https, request]
  end

  def create_access_token(response)
    expires_at = Time.zone.now + 3600 if response.code.to_i == 200
    api_name = 'allmoxy_beta'
    token = JSON.parse(response.body)['access_token']
    AccessToken.create!(api_name:, token:, expires_at:)
  end

  def access_token_check_or_refresh
    at = AccessToken.where(api_name: 'allmoxy_beta').reverse_order.limit(1).first

    time_left = at.nil? ? 0 : at.expires_at - Time.zone.now
    access_token = if time_left < 600
                     Rails.logger.info('Access token expired')
                     https, request = access_token_request
                     response = https.request(request)

                     new_at = create_access_token(response)
                     new_at.token
                   else
                     at.token
                   end

    seconds_left = ((new_at || at).expires_at - Time.zone.now).to_i
    message = "Access token good for #{seconds_left / 60} minutes or #{seconds_left} seconds"
    Rails.logger.info(message)
    access_token
  end

  def get_request(path:, url: nil)
    url ||= URI("#{@base_api_url}/#{path}")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['accept'] = 'application/json'
    request['Authorization'] = @access_token
    request['contact_key'] = Rails.application.credentials[:allmoxy_api_beta_contact_key]
    Rails.logger.info(request)
    [https, request]
  end

  def post_request(path:, url: nil, body: {})
    url ||= URI("#{@base_api_url}/#{path}")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request['accept'] = 'application/json'
    request['Content-Type'] = 'application/json'
    request['contact_key'] = Rails.application.credentials[:allmoxy_api_beta_contact_key]
    request.body = JSON.dump(body)
    Rails.logger.info(request)
    [https, request]
  end
end

class SpecialParser
  using ::JSONDeepParse

  def self.parse(json_payload)
    JSON.deep_parse(json_payload)
  end
end
