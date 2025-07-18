class DomainsController < ApplicationController
  require 'csv'

  def index; end

  def loading
    @domains = params[:domains]
    @comps = params[:comps]
    @checkdomain = params[:checkdomain]
  end

  def search # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    domains = params[:domains].to_s.strip.split(/[\s,]+/)
    fetch_comps = ActiveModel::Type::Boolean.new.cast(params[:comps])
    fetch_checkdomain = ActiveModel::Type::Boolean.new.cast(params[:checkdomain])

    @nb = NameBio.new
    @results = []

    domains.each do |domain|
      result = DomainApiRequests.send_api_request(nb: @nb, domain:, fetch_comps:, fetch_checkdomain:)
      sleep 0.5 # To avoid hitting API rate limits
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

        render plain: DomainApiRequests.generate_csv(@results)
      end
    end
  end
end
