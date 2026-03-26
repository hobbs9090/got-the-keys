class ExpandViewingOperations < ActiveRecord::Migration[8.1]
  def change
    change_table :appointments, bulk: true do |t|
      t.string :visit_outcome
      t.datetime :reminder_sent_at
    end

    add_index :appointments, :visit_outcome

    add_column :availability_windows, :capacity, :integer, null: false, default: 1
  end
end
