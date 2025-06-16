require 'rails_helper'

RSpec.describe GoogleDriveApi do
  let(:fake_client_options) { double('ClientOptions') }
  let(:fake_credentials) { double('credentials') }
  let(:fake_service) { instance_double(Google::Apis::DriveV3::DriveService) }

  before do
    # Set up client_options to support both getting and setting application_name
    allow(fake_client_options).to receive(:application_name=)
    allow(fake_service).to receive(:client_options).and_return(fake_client_options)

    # Stub authorization assignment
    allow(fake_service).to receive(:authorization=)

    # Replace the real service with our fake one
    allow(Google::Apis::DriveV3::DriveService).to receive(:new).and_return(fake_service)

    # Stub authorize method
    allow_any_instance_of(described_class).to receive(:authorize).and_return(fake_credentials)
  end

  describe '#initialize' do
    it 'initializes service and sets application name' do
      expect(fake_service).to receive(:client_options).and_return(fake_client_options)
      expect { described_class.new }.not_to raise_error
    end
  end

  describe '#get_credentials' do
    let(:authorizer) { instance_double(Google::Auth::UserAuthorizer) }

    it 'returns existing credentials' do
      allow(authorizer).to receive(:get_credentials).with('some_user').and_return(fake_credentials)
      api = described_class.new
      result = api.get_credentials(authorizer: authorizer, user_id: 'some_user')
      expect(result).to eq(fake_credentials)
    end

    it 'gets and stores credentials if user authorizes' do
      allow(authorizer).to receive(:get_credentials).and_return(nil)
      allow(authorizer).to receive(:get_authorization_url).and_return('http://example.com')
      allow(OauthSession).to receive_message_chain(:last, :code).and_return('auth_code')
      allow(authorizer).to receive(:get_and_store_credentials_from_code).and_return(fake_credentials)
      allow_any_instance_of(Object).to receive(:gets).and_return('1')

      api = described_class.new
      result = api.get_credentials(authorizer: authorizer, user_id: 'some_user')
      expect(result).to eq(fake_credentials)
    end
  end

  describe '#mime_types' do
    it 'returns expected mime types' do
      api = described_class.new
      expect(api.mime_types[:csv]).to eq('application/vnd.google-apps.spreadsheet')
      expect(api.mime_types[:doc]).to eq('application/vnd.google-apps.document')
    end
  end

  describe '#create_folder' do
    it 'creates a folder with metadata' do
      api = described_class.new
      folder_metadata = double('Folder', name: 'TestFolder')
      expect(fake_service).to receive(:create_file).and_return(folder_metadata)
      expect(Rails.logger).to receive(:debug)
      api.create_folder(parent_folder_id: '123', folder_path: 'spec/tmp/folder_test')
    end
  end

  describe '#upload_to_folder' do
    it 'uploads file with inferred mime type' do
      api = described_class.new
      file_obj = double('File', name: 'file.csv', id: 'abc123')
      expect(fake_service).to receive(:create_file).and_return(file_obj)
      expect(Rails.logger).to receive(:debug)
      result = api.upload_to_folder(parent_folder_id: 'xyz', fields: 'id, name', upload_source: 'test.csv')
      expect(result).to eq('abc123')
    end
  end

  describe '#upload_folder' do
    it 'creates folder and uploads contents' do
      api = described_class.new
      allow(api).to receive(:create_folder).and_return(double('Folder', id: 'new_folder_id'))
      allow(api).to receive(:upload_to_folder)
      allow(Dir).to receive(:glob).and_return(['file1.csv', 'file2.txt'])

      expect(api).to receive(:upload_to_folder).twice
      api.upload_folder(parent_folder_id: 'root123', folder_path: 'spec/tmp/folder_upload')
    end
  end

  describe '#list_most_recently_modified_files' do
    it 'logs file names and ids' do
      api = described_class.new
      files = [double('File', name: 'doc1.txt', id: 'id123')]
      response = double('Response', files:)
      expect(fake_service).to receive(:list_files).and_return(response)
      expect(Rails.logger).to receive(:debug).at_least(:once)
      api.list_most_recently_modified_files(int: 1)
    end
  end
end
