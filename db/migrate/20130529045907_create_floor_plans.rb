class CreateFloorPlans < ActiveRecord::Migration
  def change
    create_table :floor_plans do |t|
      t.string :floor_plans
      t.references :property, index: true

      t.timestamps
    end
  end
end
