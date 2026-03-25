class AddModernListingFieldsToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :property_type, :string, null: false, default: "House"
    add_column :properties, :bathrooms, :integer, null: false, default: 1
    add_column :properties, :listing_tagline, :string
    add_column :properties, :featured, :boolean, null: false, default: false

    add_index :properties, :featured
    add_index :properties, [:sale_status, :asking_price], name: "index_properties_on_sale_status_and_price"
  end
end
