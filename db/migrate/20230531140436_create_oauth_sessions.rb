class CreateOauthSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :oauth_sessions, &:timestamps
  end
end
