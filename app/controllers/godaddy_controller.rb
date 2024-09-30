class GodaddyController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :google_sheet

  # TODO: Schedule job in response to webhook
  def google_sheet
    # permitted_params = params[:godaddy][:changes]
    permitted_params = godaddy_params

    godaddy_params[:changes].each do |k, hsh|
      domain_name = hsh['C1']
      buy_it_now = hsh['C3']
      Rails.logger.info("domain_name: #{domain_name}, buy_it_now: #{buy_it_now}")
    end

    ProcessDomainsJob.perform_later(godaddy_params[:changes])

    # brandcrunchbot_web      | Key: R114, Value: {"C1"=>"xploreworld.com", "C2"=>"", "C3"=>11}
    # brandcrunchbot_web      | Key: R115, Value: {"C1"=>"zerobeast.com", "C2"=>"", "C3"=>11}
    # brandcrunchbot_web      | Key: R116, Value: {"C1"=>"zeropump.com", "C2"=>"", "C3"=>11}
    #

    render json: permitted_params.to_json, status: :ok
  end

  private

  def godaddy_params
    params.require(:godaddy).permit(:sheetName, changes: {})
  end
end
