class AddUserIdToSavedSearches < ActiveRecord::Migration[8.1]
  def up
    add_reference :saved_searches, :user, foreign_key: true, null: true

    SavedSearch.reset_column_information
    SavedSearch.find_each do |saved_search|
      user = User.find_by("lower(email) = ?", saved_search.email.to_s.downcase)
      if user
        saved_search.update_column(:user_id, user.id)
      else
        saved_search.delete
      end
    end

    change_column_null :saved_searches, :user_id, false
  end

  def down
    change_column_null :saved_searches, :user_id, true
    remove_reference :saved_searches, :user, foreign_key: true
  end
end
