class GoogleSheetsApi
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS
  attr_reader :service

  def initialize
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  # def request_new_authorization(authorizer, user_id, base_url)
  #   # Token is missing or invalid, request authorization
  #   url = authorizer.get_authorization_url(base_url:)
  #   Rails.logger.info "Requesting new authorization. Open the following URL in the browser:\n#{url}"
  #
  #   puts 'Have you authorised the application?'
  #   puts '1. Yes'
  #   puts '0. No'
  #   response = gets.strip.to_i
  #   # code = OauthSession.last.code if response == 1
  #
  #   # Prompt user for authorization if needed
  #   response = OauthSession.last if response == 1
  #   raise 'No valid authorization code found. Please reauthorize the app.' unless response&.code
  #
  #   Rails.logger.info 'Authorization code found, exchanging for credentials...'
  #   authorizer.get_and_store_credentials_from_code(user_id:, code: response.code, base_url:)
  # end

  # def get_credentials(authorizer:, user_id:)
  #   base_url = Rails.env.match?('production') ? REDIRECT_URI : LOOPBACK_ADDRESS
  #   credentials = authorizer.get_credentials(user_id)
  #
  #   if credentials.nil?
  #     # Token is missing, request authorization
  #     request_new_authorization(authorizer, user_id, base_url)
  #
  #   else
  #     Rails.logger.info "Credentials found for user #{user_id}. Checking expiration..."
  #
  #     # Ensure token refresh if it's expired
  #     if credentials.expired?
  #       Rails.logger.info 'Access token expired, attempting to refresh token...'
  #       begin
  #         credentials.refresh!
  #       rescue Signet::AuthorizationError => e
  #         raise e unless e.message.include?('invalid_grant')
  #
  #         Rails.logger.error 'Refresh token is invalid or revoked. Reauthorizing...'
  #         request_new_authorization(authorizer, user_id, base_url)
  #
  #         # Re-raise if it's another issue
  #       end
  #     end
  #
  #     credentials
  #   end
  # end

  def authorize
    # Load the service account credentials from Rails credentials
    creds = Rails.application.credentials.google_client_secret_server

    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(creds.to_json),
      scope: SCOPE
    )
    authorizer.fetch_access_token!
    authorizer
  end

  def get_spreadsheet_values(spreadsheet_id:, range:)
    response = @service.get_spreadsheet_values(spreadsheet_id, range)
    Rails.logger.info 'No data found.' if response.values.nil?
    response
  end

  def append_spreadsheet_values(spreadsheet_id:, range:, values:, value_input_option: 'USER_ENTERED')
    values_range = Google::Apis::SheetsV4::ValueRange.new(values:)
    @service.append_spreadsheet_value(spreadsheet_id, range, values_range, value_input_option:)
  end

  def clear_values(spreadsheet_id:, range:)
    request_body = Google::Apis::SheetsV4::ClearValuesRequest.new
    @service.clear_values(spreadsheet_id, range, request_body)
  end

  def update_values(spreadsheet_id:, range:, csv_path:)
    request_body = Google::Apis::SheetsV4::ValueRange.new
    values = CSV.open(csv_path).to_a
    request_body.values = values

    @service.update_spreadsheet_value(spreadsheet_id, range, request_body, value_input_option: 'USER_ENTERED')
  end

  def update_values_from_csv_object(spreadsheet_id:, range:, csv_object:)
    request_body = Google::Apis::SheetsV4::ValueRange.new
    request_body.values = csv_object
    @service.update_spreadsheet_value(spreadsheet_id, range, request_body, value_input_option: 'USER_ENTERED')
  end

  def update_values_from_hash(spreadsheet_id:, range:, headers:, hsh_ary:)
    request_body = Google::Apis::SheetsV4::ValueRange.new
    values = [headers]
    rows = hsh_ary.map { |hsh| hsh.values.pluck(:value) }
    rows.each { |row| values << row }
    request_body.values = values
    @service.update_spreadsheet_value(spreadsheet_id, range, request_body, value_input_option: 'USER_ENTERED')
  end

  def update_values_from_simple_hash_array(spreadsheet_id:, range:, hsh_ary:, headers: nil)
    request_body = Google::Apis::SheetsV4::ValueRange.new
    values = headers ? [headers] : []
    rows = hsh_ary.map(&:values)
    rows.each { |row| values << row }
    request_body.values = values
    @service.update_spreadsheet_value(spreadsheet_id, range, request_body, value_input_option: 'USER_ENTERED')
  end

  def append_values_from_simple_hash_array(spreadsheet_id:, range:, hsh_ary:, headers: nil)
    values = headers ? [headers] : []
    rows = hsh_ary.map(&:values)
    rows.each { |row| values << row }
    values_range = Google::Apis::SheetsV4::ValueRange.new(values:)
    @service.append_spreadsheet_value(spreadsheet_id, range, values_range, value_input_option: 'USER_ENTERED')
  end

  def append_values_from_nested_array(spreadsheet_id:, range:, nested_array:)
    request_body = Google::Apis::SheetsV4::ValueRange.new
    request_body.values = nested_array
    @service.append_spreadsheet_value(spreadsheet_id, range, request_body, value_input_option: 'USER_ENTERED')
  end

  def here_be_dragons(spreadsheet_id:, range:)
    csv_path = 'spec/fixtures/here_be_dragons.csv'
    clear_values(spreadsheet_id:, range:)
    update_values(spreadsheet_id:, range:, csv_path:)
  end
end

# def get_credentials(authorizer:, user_id:)
#   base_url = Rails.env.match?('production') ? REDIRECT_URI : LOOPBACK_ADDRESS
#   credentials = authorizer.get_credentials(user_id)
#
#   # TODO: Use a callback to monitor the number OauthSession records
#   if credentials.nil?
#     url = authorizer.get_authorization_url(base_url:)
#     puts "Open the following URL in the browser and enter the resulting code after authorization:\n#{url}"
#     puts 'Have you authorised the application?'
#     puts '1. Yes'
#     puts '0. No'
#     response = gets.strip.to_i
#     code = OauthSession.last.code if response == 1
#     authorizer.get_and_store_credentials_from_code(user_id:, code:, base_url:)
#   else
#     credentials
#   end
# end
