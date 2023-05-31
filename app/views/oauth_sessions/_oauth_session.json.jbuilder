json.extract! oauth_session, :id, :created_at, :updated_at
json.url oauth_session_url(oauth_session, format: :json)
