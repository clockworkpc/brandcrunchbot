class GoogleSheetsApi
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS
  attr_reader :service

  def initialize
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def get_credentials(authorizer:, user_id:)
    base_url = Rails.env.match?('production') ? REDIRECT_URI : LOOPBACK_ADDRESS
    credentials = authorizer.get_credentials(user_id)

    # TODO: Use a callback to monitor the number OauthSession records
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url:)
      puts "Open the following URL in the browser and enter the resulting code after authorization:\n#{url}"
      puts 'Have you authorised the application?'
      puts '1. Yes'
      puts '0. No'
      response = gets.strip.to_i
      code = OauthSession.last.code if response == 1
      authorizer.get_and_store_credentials_from_code(user_id:, code:, base_url:)
    else
      credentials
    end
  end

  def authorize
    # credentials_key = :google_client_secret
    credentials_key = Rails.env.eql?('production') ? :google_client_secret_prod : :google_client_secret
    credentials = Rails.application.credentials[credentials_key].deep_stringify_keys
    client_id = Google::Auth::ClientId.from_hash(credentials)
    token_store = Google::Auth::Stores::RedisTokenStore.new(redis: Redis.new)
    # token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH_SHEETS
    authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
    user_id = 'brandcrunch'
    get_credentials(authorizer:, user_id:)
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

  def here_be_dragons(spreadsheet_id:, range:)
    csv_path = 'spec/fixtures/here_be_dragons.csv'
    clear_values(spreadsheet_id:, range:)
    update_values(spreadsheet_id:, range:, csv_path:)
  end
end
