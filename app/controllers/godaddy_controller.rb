class GodaddyController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :google_sheet

  # TODO: Schedule job in response to webhook
  def google_sheet
    data = params[:godaddy] || params
    range = "#{data['sheet_name']}!A2:C"
    service = BuyItNowBotScheduler.new
    service.call(range:)
    render json: { message: 'Data received successfully' }, status: :ok
  rescue ActionController::UnfilteredParameters => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def godaddy_params
    params.require(:godaddy).permit(:sheetName, changes: {})
  end
end
