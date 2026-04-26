class CreateApiRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :api_refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :token_digest, null: false
      t.string  :device_id,    null: false
      t.string  :device_name
      t.string  :user_agent
      t.string  :ip_address
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.datetime :last_used_at
      t.timestamps
    end

    add_index :api_refresh_tokens, :token_digest, unique: true
    add_index :api_refresh_tokens, [:user_id, :device_id]
    add_index :api_refresh_tokens, :expires_at
  end
end
