class HashAppointmentAccessTokens < ActiveRecord::Migration[8.1]
  def up
    add_column :appointments, :access_token_digest, :string
    add_column :appointments, :access_token_expires_at, :datetime

    say_with_time "Backfilling appointment access token digests" do
      select_all("SELECT id, access_token, created_at FROM appointments").each do |row|
        token = row.fetch("access_token").to_s
        next if token.blank?

        digest = Digest::SHA256.hexdigest(token)
        expires_at = Time.zone.parse(row.fetch("created_at").to_s) + 30.days
        update <<~SQL.squish
          UPDATE appointments
          SET access_token_digest = #{quote(digest)},
              access_token_expires_at = #{quote(expires_at)}
          WHERE id = #{row.fetch("id").to_i}
        SQL
      end
    end

    change_column_null :appointments, :access_token_digest, false
    change_column_null :appointments, :access_token_expires_at, false
    remove_index :appointments, :access_token
    remove_column :appointments, :access_token
    add_index :appointments, :access_token_digest, unique: true
    add_index :appointments, :access_token_expires_at
  end

  def down
    add_column :appointments, :access_token, :string

    say_with_time "Restoring placeholder appointment access tokens" do
      select_all("SELECT id FROM appointments").each do |row|
        update <<~SQL.squish
          UPDATE appointments
          SET access_token = #{quote(SecureRandom.hex(32))}
          WHERE id = #{row.fetch("id").to_i}
        SQL
      end
    end

    change_column_null :appointments, :access_token, false
    remove_index :appointments, :access_token_digest
    remove_index :appointments, :access_token_expires_at
    remove_column :appointments, :access_token_digest
    remove_column :appointments, :access_token_expires_at
    add_index :appointments, :access_token, unique: true
  end
end
