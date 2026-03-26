class AddListingOperationsToProperties < ActiveRecord::Migration[8.1]
  def change
    change_table :properties, bulk: true do |t|
      t.string :listing_state, null: false, default: "published"
      t.datetime :published_at
      t.string :tenure
      t.string :council_tax_band
      t.string :furnishing
      t.date :available_from
      t.string :parking
      t.string :outdoor_space
      t.string :epc_rating
      t.integer :floor_area_sq_ft
      t.integer :deposit_amount
      t.boolean :pets_allowed, null: false, default: false
      t.integer :service_charge_amount
      t.integer :lease_length_years
    end

    add_index :properties, :listing_state
    add_index :properties, :available_from

    change_table :photos, bulk: true do |t|
      t.integer :position, null: false, default: 0
      t.boolean :primary, null: false, default: false
      t.string :caption
    end

    add_index :photos, [:property_id, :position]

    change_table :floor_plans, bulk: true do |t|
      t.string :label
      t.integer :position, null: false, default: 0
    end

    add_index :floor_plans, [:property_id, :position]

    reversible do |direction|
      direction.up do
        execute <<~SQL
          UPDATE properties
          SET published_at = COALESCE(updated_at, CURRENT_TIMESTAMP)
          WHERE listing_state = 'published' AND published_at IS NULL
        SQL
      end
    end
  end
end
