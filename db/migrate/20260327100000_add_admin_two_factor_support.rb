class AddAdminTwoFactorSupport < ActiveRecord::Migration[8.1]
  def change
    change_table :admins, bulk: true do |t|
      t.string :otp_secret
      t.integer :consumed_timestep
      t.boolean :otp_required_for_login, null: false, default: false
      t.json :otp_backup_codes
    end

    add_column :booking_configurations, :admin_two_factor_mode, :string, null: false, default: "disabled"
  end
end
