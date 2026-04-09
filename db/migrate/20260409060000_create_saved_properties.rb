class CreateSavedProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_properties do |t|
      t.references :user, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true

      t.timestamps
    end

    add_index :saved_properties, [:user_id, :property_id], unique: true
  end
end
