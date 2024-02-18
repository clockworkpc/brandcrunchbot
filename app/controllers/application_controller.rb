class ApplicationController < ActionController::Base
  # before_action :authenticate_user!
end

def after_sign_out_path_for(resource_or_scope = nil) # rubocop:disable Lint/UnusedMethodArgument
  new_user_session_path
end

def slack_current_user
  text = "Office Robot is working on behalf of #{current_user.email}"
  sas = SlackApiService.new
  sas.post_message(text:)
end

# rubocop:disable Metrics/MethodLength
def text_for_private_slack
  time = Time.now.localtime('-07:00').strftime('%r')
  action = params[:action].to_s.titleize
  reject_regex = /action|authenticity_token|commit|controller/
  lines = params.keys
                .reject { |k0| k0.to_s.match?(reject_regex) }
                .select { |k1| params[k1].to_i == 1 }
                .map { |k2| k2.gsub('_inputs', '').titleize }

  lines_text = if lines.count == 2
                 lines.join(' and ')
               elsif lines.count < 2
                 lines.first
               else
                 lines.last.insert(0, 'and ')
                 lines.join(', ')
               end

  <<~HEREDOC
    Office Robot received a request at #{time} to update *#{action}* for *#{lines_text}* on your behalf, and will start work as soon as possible.
  HEREDOC
end
# rubocop:enable Metrics/MethodLength

def slack_current_user_privately
  text = text_for_private_slack
  sas = SlackApiService.new
  email = current_user.email
  begin
    sas.post_message_to_user(email:, text:)
  rescue StandardError => e
    Rails.logger.info(e)
    Rails.logger.info("No slack account associated with #{email}.")
  end
end

def log_current_user
  Rails.logger.info("CURRENT USER: #{current_user.email}".light_red)
  Rails.logger.info("AUTHORISED? #{current_user.authorized?}".light_red)
end
