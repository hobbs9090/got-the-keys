class AddLanguageToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :language, :string
  end
end
