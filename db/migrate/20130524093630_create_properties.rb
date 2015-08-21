class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.integer :asking_price
      t.text :property_description, :limit => nil
      t.string :sale_status, index: true
      t.string :address_line_1
      t.string :address_line_2
      t.string :town_city
      t.string :county
      t.string :postcode, index: true
      t.string :country
      t.string :image_file_name
      t.integer :bedrooms, index: true
      t.references :user, index: true

      t.timestamps
    end
  end
end



