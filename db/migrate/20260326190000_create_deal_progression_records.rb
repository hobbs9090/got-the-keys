class CreateDealProgressionRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :offers do |t|
      t.references :property, null: false, foreign_key: true
      t.references :admin, null: true, foreign_key: true
      t.string :public_reference, null: false
      t.string :buyer_name, null: false
      t.string :buyer_email, null: false
      t.string :buyer_phone, null: false
      t.integer :amount, null: false
      t.string :status, null: false, default: "received"
      t.string :chain_position
      t.text :notes
      t.text :internal_notes
      t.datetime :decision_made_at
      t.timestamps
    end

    add_index :offers, :public_reference, unique: true
    add_index :offers, :status

    create_table :offer_events do |t|
      t.references :offer, null: false, foreign_key: true
      t.references :admin, null: true, foreign_key: true
      t.string :event_type, null: false
      t.string :from_status
      t.string :to_status
      t.text :message
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    create_table :rental_applications do |t|
      t.references :property, null: false, foreign_key: true
      t.references :admin, null: true, foreign_key: true
      t.string :public_reference, null: false
      t.string :applicant_name, null: false
      t.string :applicant_email, null: false
      t.string :applicant_phone, null: false
      t.date :move_in_date, null: false
      t.string :status, null: false, default: "received"
      t.boolean :guarantor_required, null: false, default: false
      t.boolean :guarantor_available, null: false, default: false
      t.text :affordability_notes
      t.text :notes
      t.text :internal_notes
      t.datetime :decision_made_at
      t.timestamps
    end

    add_index :rental_applications, :public_reference, unique: true
    add_index :rental_applications, :status

    create_table :rental_application_events do |t|
      t.references :rental_application, null: false, foreign_key: true
      t.references :admin, null: true, foreign_key: true
      t.string :event_type, null: false
      t.string :from_status
      t.string :to_status
      t.text :message
      t.datetime :occurred_at, null: false
      t.timestamps
    end
  end
end
