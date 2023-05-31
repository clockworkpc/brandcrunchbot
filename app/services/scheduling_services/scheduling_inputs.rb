module SchedulingServices
  class SchedulingInputs
    def checked_params(input_params:)
      input_params.select { |_k, v| v.eql?('1') }
    end

    def sas
      @sas ||= SlackApiService.new
    end

    def refresh_reports_slack_parent(checked_params:)
      refreshed_reports = checked_params.keys.reject { |k| k.eql?('dev') }.map(&:titleize)
      text = "The following Scheduling Inputs are to be refreshed: #{refreshed_reports.join(', ')}"
      sas.post_message(text:)
    end

    def refresh_reports_slack_complete(sas_parent:, checked_params:)
      refreshed_reports = checked_params.keys.reject { |k| k.eql?('dev') }.map(&:titleize)
      text = "The following Scheduling Inputs have been refreshed: #{refreshed_reports.join(', ')}"
      sas.post_reply(sas_parent:, text:)
    end
  end
end
