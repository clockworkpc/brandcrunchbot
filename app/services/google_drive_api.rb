class GoogleDriveApi
  SCOPE = Google::Apis::DriveV3::AUTH_DRIVE
  attr_reader :service

  def initialize
    @service = Google::Apis::DriveV3::DriveService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def get_credentials(authorizer:, user_id:)
    base_url = Rails.env.match?('production') ? REDIRECT_URI : LOOPBACK_ADDRESS
    credentials = authorizer.get_credentials(user_id)

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
    user_id = 'google_drive'
    get_credentials(authorizer:, user_id:)
  end

  def list_most_recently_modified_files(int: 10)
    response = @service.list_files(page_size: int,
                                   fields: 'nextPageToken, files(id, name)')
    puts 'Files:'
    puts 'No files found' if response.files.empty?
    response.files.each do |file|
      puts "#{file.name} (#{file.id})"
    end
  end

  def mime_types
    {
      csv: 'application/vnd.google-apps.spreadsheet',
      ods: 'application/vnd.google-apps.spreadsheet',
      xls: 'application/vnd.google-apps.spreadsheet',
      xlsx: 'application/vnd.google-apps.spreadsheet',
      txt: 'application/vnd.google-apps.document',
      doc: 'application/vnd.google-apps.document',
      docx: 'application/vnd.google-apps.document',
      odt: 'application/vnd.google-apps.document'
    }

    # application/vnd.google-apps.audio
    # application/vnd.google-apps.document
    # application/vnd.google-apps.drive-sdk
    # application/vnd.google-apps.drawing
    # application/vnd.google-apps.file
    # application/vnd.google-apps.folder
    # application/vnd.google-apps.form
    # application/vnd.google-apps.fusiontable
    # application/vnd.google-apps.jam
    # application/vnd.google-apps.map
    # application/vnd.google-apps.photo
    # application/vnd.google-apps.presentation
    # application/vnd.google-apps.script
    # application/vnd.google-apps.shortcut
    # application/vnd.google-apps.site
    # application/vnd.google-apps.spreadsheet
    # application/vnd.google-apps.unknown
    # application/vnd.google-apps.video
  end

  def create_folder(parent_folder_id:, folder_path:, team_drive_id: nil) # rubocop:disable Metrics/MethodLength
    name = File.basename(folder_path)
    mime_type = 'application/vnd.google-apps.folder'

    file_metadata = { name:, mime_type: }
    file_metadata[:parents] = [parent_folder_id] if parent_folder_id

    if team_drive_id
      file_metadata[:team_drive_id] = team_drive_id
      file_metadata[:drive_id] = team_drive_id
      supports_all_drives = true
      supports_team_drives = true
    end

    fields = %w[id name parents mimeType description].join(', ')

    folder = @service.create_file(file_metadata,
                                  supports_all_drives:,
                                  supports_team_drives:,
                                  fields:)

    puts Rainbow("Folder created: #{folder.name}").orange
    folder
  end

  def upload_to_folder(parent_folder_id:, fields:, upload_source:, mime_type: nil)
    name = File.basename(upload_source)
    extname = File.extname(upload_source).delete('.').to_sym
    mime_type = mime_types[extname] if mime_type.nil?

    file_metadata = { name:, mime_type: }
    file_metadata[:parents] = [parent_folder_id] if parent_folder_id
    file = @service.create_file(file_metadata,
                                fields:,
                                upload_source:,
                                supports_all_drives: true)
    puts Rainbow("File created: #{file.name}").orange
    file.id
  end

  def upload_folder(parent_folder_id:, folder_path:, team_drive_id: nil, scan_int: nil)
    folder = create_folder(parent_folder_id:, folder_path:, team_drive_id:)
    files = if scan_int.nil?
              Dir.glob("#{folder_path}/**")
            else
              Utils.list_files_without_duplicates(path: folder_path, scan_int:)
            end

    fields = %w[id name parents mimeType description].join(', ')

    files.each do |file|
      upload_to_folder(
        parent_folder_id: folder.id,
        fields:,
        upload_source: file
      )
    end
  end
end
