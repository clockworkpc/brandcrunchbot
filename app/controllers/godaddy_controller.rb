class GodaddyController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :google_sheet

  # TODO: Schedule job in response to webhook
  def google_sheet
    # If the parameters are wrapped under "godaddy", use the wrapped params, otherwise use the regular params
    data = params[:godaddy] || params

    # Permit the nested parameters properly
    permitted_data = data.permit(:sheetName, changes: {})

    # Process or enqueue a job with permitted parameters
    ProcessDomainsJob.perform_later(permitted_data.to_h)

    render json: { message: 'Data received successfully' }, status: :ok
  rescue ActionController::UnfilteredParameters => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def godaddy_params
    params.require(:godaddy).permit(:sheetName, changes: {})
  end
end
