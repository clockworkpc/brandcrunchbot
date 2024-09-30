class GodaddyController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :google_sheet

  # TODO: Schedule job in response to webhook
  def google_sheet
    Rails.logger.info(params)
    render json: godaddy_params.to_json, status: :ok
  end

  private

  def godaddy_params
    params.require(:godaddy).permit(:sheetName, changes: {})
  end
end
