class AddPropertiesCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :properties_count, :integer
  end
end
