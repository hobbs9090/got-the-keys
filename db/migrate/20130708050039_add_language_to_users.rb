class AddLanguageToUsers < ActiveRecord::Migration
  def change
    add_column :users, :language, :string, index: true
  end
end
