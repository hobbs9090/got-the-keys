class AddAdminProvisionedToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :admin_provisioned, :boolean, default: false, null: false
  end
end
