class ApplicationController < ActionController::Base
  before_action :authenticate_user!
end

def after_sign_out_path_for(resource_or_scope = nil) # rubocop:disable Lint/UnusedMethodArgument
  new_user_session_path
end

def log_current_user
  Rails.logger.info("CURRENT USER: #{current_user.email}".light_red)
  Rails.logger.info("AUTHORISED? #{current_user.authorized?}".light_red)
end
