class CreateViewingTimes < ActiveRecord::Migration
  def change
    create_table :viewing_times do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.references :property, index: true

      t.timestamps
    end
  end
end
