class ZapsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    finish = zap_params[:zap].eql?('true') &&
             zap_params[:finish].eql?('true') &&
             zap_params[:api_key].eql?(Rails.application.credentials[:zapier_api_key])

    if finish
      Rails.logger.info('Refreshing orders_input in Finish Price Analysis'.green)
      service = SchedulingServices::AnalysisInputs.new
      service.delay.call

      json = zap_params.to_json
      status = :ok
    else
      json = { ok: false }
      status = :unprocessable_entity
    end

    render json:, status:
  end

  private

  # Only allow a list of trusted parameters through.
  def zap_params
    params.permit(:zap, :finish, :api_key)
  end
end
