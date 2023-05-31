class AddCodeAndScopeToOauthSessions < ActiveRecord::Migration[7.0]
  def change
    add_column :oauth_sessions, :code, :string
    add_column :oauth_sessions, :scope, :string
  end
end
