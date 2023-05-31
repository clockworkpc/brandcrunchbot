require 'google/apis/drive_v3'
require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'googleauth/stores/redis_token_store'
require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
LOOPBACK_ADDRESS = 'http://127.0.0.1:3000'.freeze
REDIRECT_URI = ENV.fetch('HOST', nil)
APPLICATION_NAME = 'PDI Business Solutions'.freeze
CREDENTIALS_PATH = 'config/credentials/google_client_secret.json'.freeze
TOKEN_PATH_DRIVE = 'config/credentials/google_token_drive.yaml'.freeze
TOKEN_PATH_SHEETS = 'config/credentials/google_token_sheets.yaml'.freeze
