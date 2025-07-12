require 'net/http'
require 'uri'
require 'json'

class NameBio
  API_KEY = Rails.application.credentials.name_bio.api_key
  API_EMAIL = Rails.application.credentials.name_bio.api_email
  URL_CHECK_DOMAIN = 'https://api.namebio.com/checkdomain/'
  URL_COMPS = 'https://api.namebio.com/comps/'

  attr_writer :rate_limit_delay

  def initialize(rate_limit_delay: 1.1)
    @rate_limit_delay = rate_limit_delay
  end

  def send_request(domain:, api_url:)
    raise ArgumentError, 'Domain cannot be nil or empty' if domain.blank?

    uri = URI(api_url)
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(email: API_EMAIL, key: API_KEY, domain:)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    binding.irb

    parse_response(response, domain)
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
