class GodaddyController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :google_sheet

  def google_sheet
    render json: godaddy_params.to_json, status: :ok
  end

  private

  def godaddy_params
    params.require(:godaddy).permit(:sheetName, changes: {})
  end
end
