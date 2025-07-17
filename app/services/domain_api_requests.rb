require 'csv'

module DomainApiRequests
  module_function

  def valid_request_params?(domain:)
    return false if domain.blank?
    return false if domain.length < 3 || domain.length > 255
    return false if domain.match?(/[^a-zA-Z0-9.-]/)
    return false if domain.start_with?('.') || domain.end_with?('.')

    true
  end

  def send_api_request(nb:, domain:, fetch_comps:, fetch_checkdomain:)
    return if domain.blank?
    return unless fetch_comps || fetch_checkdomain

    request_type = fetch_comps ? 'comps' : 'checkdomain'
    Rails.logger.info("Processing domain: #{domain} for request type: #{request_type}")
    domain = domain.strip.downcase
    return unless valid_request_params?(domain:)

    if fetch_comps
      nb.send_comps_request(domain: domain).merge('type' => 'comps', 'domain' => domain)
    elsif fetch_checkdomain
      nb.send_check_domain_request(domain: domain).merge('type' => 'checkdomain', 'domain' => domain)
    end
  end

  def generate_csv(results)
    CSV.generate(headers: true) do |csv|
      csv << %w[Domain Type Field Value]

      results.each do |result|
        domain = result['domain']
        type = result['type']

        result.each do |key, value|
          next if %w[domain type].include?(key)

          if value.is_a?(Array)
            value.each_with_index do |v, i|
              csv << [domain, type, "#{key}[#{i}]", v]
            end
          else
            csv << [domain, type, key, value]
          end
        end
      end
    end
  end
end
