class DomainsController < ApplicationController
  require 'csv'

  def index; end

  def search # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    domains = params[:domains].to_s.strip.split(/[\s,]+/)
    fetch_comps = ActiveModel::Type::Boolean.new.cast(params[:comps])
    fetch_checkdomain = ActiveModel::Type::Boolean.new.cast(params[:checkdomain])
    fetch_comps || fetch_checkdomain

    @nb = NameBio.new
    @results = []

    domains.each do |domain|
      result = send_api_request(domain:, fetch_comps:, fetch_checkdomain:)
      @results << result if result
    end

    session[:namebio_results] = @results

    redirect_to results_domains_path
  end

  def results
    @results = session[:namebio_results] || []

    respond_to do |format|
      format.html # renders results.html.erb
      format.csv do
        headers['Content-Disposition'] = 'attachment; filename="namebio_results.csv"'
        headers['Content-Type'] ||= 'text/csv'

        render plain: generate_csv(@results)
      end
    end
  end

  private

  def generate_csv(results) # rubocop:disable Metrics/MethodLength
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

  def valid_request_params?(domain:)
    return false if domain.blank?

    return false if domain.length < 3 || domain.length > 255

    return false if domain.match?(/[^a-zA-Z0-9.-]/) # Only allow alphanumeric characters, dots, and hyphens

    return false if domain.start_with?('.') || domain.end_with?('.') # Cannot start or end with a dot

    true
  end

  def send_api_request(domain:, fetch_comps:, fetch_checkdomain:)
    return if domain.blank?

    return unless fetch_comps || fetch_checkdomain

    request_type = fetch_comps ? 'comps' : 'checkdomain'
    Rails.logger.info("Processing domain: #{domain} for request type: #{request_type}")
    domain = domain.strip.downcase
    return unless valid_request_params?(domain:)

    if fetch_comps
      @nb.send_comps_request(domain: domain).merge('type' => 'comps', 'domain' => domain)
    elsif fetch_checkdomain
      @nb.send_check_domain_request(domain: domain).merge('type' => 'checkdomain', 'domain' => domain)
    end
  end
end
