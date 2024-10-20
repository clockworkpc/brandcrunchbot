class GodaddyController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :google_sheet

  # TODO: Schedule job in response to webhook
  def google_sheet
    data = params[:godaddy] || params
    raw_changes = data[:changes] || {}
    changes = raw_changes.values
    service = BuyItNowBotScheduler.new
    service.call(changes:)
    render json: { message: 'Data received successfully' }, status: :ok
  rescue ActionController::UnfilteredParameters => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def godaddy_params
    params.require(:godaddy).permit(:sheet_name, changes: {})
  end
end
