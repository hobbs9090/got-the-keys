class AddChronologyToProperties < ActiveRecord::Migration[8.1]
  def change
    change_table :properties, bulk: true do |t|
      t.integer :year_built
      t.integer :refurbished_year
    end

    add_index :properties, :year_built
    add_index :properties, :refurbished_year
  end
end
