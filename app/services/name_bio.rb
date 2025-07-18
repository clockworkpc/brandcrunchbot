require 'net/http'
require 'uri'
require 'json'

class NameBio
  API_KEY = Rails.application.credentials.name_bio.api_key
  API_EMAIL = Rails.application.credentials.name_bio.api_email
  BASE_URL = 'https://api.namebio.com'.freeze
  URL_CHECK_DOMAIN = "#{BASE_URL}/checkdomain/".freeze
  URL_COMPS = "#{BASE_URL}/comps/".freeze

  attr_writer :rate_limit_delay

  def initialize(rate_limit_delay: 1.1)
    @rate_limit_delay = rate_limit_delay
  end

  def send_request(url:, url_params: {})
    raise ArgumentError, 'URL cannot be nil or empty' if url.blank?

    uri = URI(url)

    # Include everything in the POST body, not in the query string
    request = Net::HTTP::Post.new(uri)
    request.set_form_data({ email: API_EMAIL, key: API_KEY }.merge(url_params))

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    parse_response(response, url_params[:domain])
  end

  def send_comps_request(domain:, order_by: 'price', order_dir: 'desc', monthsold: 60, match_sld_any_tld: false)
    raise ArgumentError, 'Domain cannot be nil or empty' if domain.blank?

    url = URL_COMPS
    url_params = {
      domain:,
      order_by:,
      order_dir:,
      monthsold:,
      match_sld_any_tld:
    }

    send_request(url:, url_params:)
  end

  def send_check_domain_request(domain:)
    raise ArgumentError, 'Domain cannot be nil or empty' if domain.blank?

    url = URL_CHECK_DOMAIN
    url_params = { domain: }

    send_request(url:, url_params:)
  end

  def parse_response(response, domain)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      Rails.logger.warn("Failed to fetch #{domain} - HTTP #{response.code}")
      { domain: domain, error: response.code.to_i, message: response.body }
    end
  end

  def check_domains(domains: [])
    raise ArgumentError, 'No domains provided' if domains.empty?

    api_url = URL_CHECK_DOMAIN

    results = domains.map do |domain|
      result = send_request(domain:, api_url:)
      sleep @rate_limit_delay
      result
    end

    output_results(results)
  end

  private

  def output_results(results)
    json = JSON.pretty_generate(results)
    Rails.logger.info { "NameBio Results:\n#{json}" }

    timestamp = Time.current.strftime('%Y-%m-%d_%H-%M-%S')
    path = Rails.root.join('tmp', "namebio_results_#{timestamp}.json")

    File.write(path, json)
    Rails.logger.info "Results saved to #{path}"
  end
end
