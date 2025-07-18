class GodaddyController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :google_sheet
  skip_before_action :authenticate_user!, only: :google_sheet

  # TODO: Schedule job in response to webhook
  def google_sheet
    permitted_params = godaddy_params.to_h
    changes = permitted_params[:changes]&.values || []
    service = BuyItNowBotScheduler.new
    service.call(changes:)
    render json: { message: 'Data received successfully' }, status: :ok
  rescue ActionController::ParameterMissing, ActionController::UnfilteredParameters => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def godaddy_params
    params.require(:godaddy).permit(:sheet_name, changes: {})
  end
end
