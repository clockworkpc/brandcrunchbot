class SchedulingServicesController < ApplicationController
  before_action :authenticate_user!
  before_action :log_current_user
  before_action :slack_current_user, except: [:index]
  before_action :slack_current_user_privately, except: [:index]

  def index
  end

  def ancillary_inputs
    service = SchedulingServices::AncillaryInputs.new
    service.delay.call(ancillary_input_params)
    notice = SchedulingServicesHelper.ancillary_inputs_notice(ancillary_input_params)
    redirect_to scheduling_services_url, notice:
  end

  def v4_inputs
    service = SchedulingServices::V4Inputs.new
    service.delay.call(v4_input_params)
    notice = SchedulingServicesHelper.v4_inputs_notice(v4_input_params)
    redirect_to scheduling_services_url, notice:
  end

  def production_inputs
    service = SchedulingServices::ProductionInputs.new
    service.delay.call(production_input_params)
    notice = SchedulingServicesHelper.production_inputs_notice(production_input_params)
    redirect_to scheduling_services_url, notice:
  end

  def all_inputs
    service = SchedulingServices::AllInputs.new
    service.delay.call(all_input_params)
    notice = SchedulingServicesHelper.all_inputs_notice(all_input_params)
    redirect_to scheduling_services_url, notice:
  end

  # def status_history_report
  # end

  private

  def ancillary_input_params
    params.permit(
      :action, :authenticity_token, :commit, :controller,
      :projection_report,
      :shipping_report,
      :tags_report
    )
  end

  def v4_input_params
    params.permit(
      :action, :authenticity_token, :commit, :controller,
      :doors_v5_inputs,
      :drawers_v5_inputs,
      :specialty_v5_inputs,
      :finish_v5_inputs
    )
  end

  def production_input_params
    params.permit(
      :action, :authenticity_token, :commit, :controller,
      :doors_inputs,
      :drawers_inputs,
      :specialty_inputs
    )
  end

  def all_input_params
    params.permit(
      :action, :authenticity_token, :commit, :controller,
      :all_v4_inputs,
      :all_production_inputs
    )
  end
end
