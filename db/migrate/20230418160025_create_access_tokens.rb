class CreateAccessTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :access_tokens do |t|
      t.string :api_name
      t.string :token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
