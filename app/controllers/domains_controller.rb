class DomainsController < ApplicationController
  require 'csv'

  def index; end

  def search
    domains = params[:domains].to_s.strip.split(/[\s,]+/) # handle comma/space/newline separation
    fetch_comps = ActiveModel::Type::Boolean.new.cast(params[:comps])
    fetch_checkdomain = ActiveModel::Type::Boolean.new.cast(params[:checkdomain])

    @nb = NameBio.new
    @results = []

    domains.each do |domain|
      if fetch_comps
        result = @nb.send_comps_request(domain: domain).merge("type" => "comps", "domain" => domain)
      elsif fetch_checkdomain
        result = @nb.send_check_domain_request(domain: domain).merge("type" => "checkdomain", "domain" => domain)
      else
        next
      end
      @results << result
    end

    session[:namebio_results] = @results

    redirect_to domains_results_path
  end

  def results
    @results = session[:namebio_results] || []

    respond_to do |format|
      format.html # renders results.html.erb
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"namebio_results.csv\""
        headers['Content-Type'] ||= 'text/csv'

        render plain: generate_csv(@results)
      end
    end
  end

  private

  def generate_csv(results)
    CSV.generate(headers: true) do |csv|
      csv << ["Domain", "Type", "Field", "Value"]

      results.each do |result|
        domain = result["domain"]
        type = result["type"]

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

