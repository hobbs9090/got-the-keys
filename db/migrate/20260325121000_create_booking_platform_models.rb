class CreateBookingPlatformModels < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_configurations do |t|
      t.integer :slot_duration_minutes, null: false, default: 45
      t.integer :lead_time_hours, null: false, default: 4
      t.integer :buffer_minutes, null: false, default: 15
      t.string :office_opens_at, null: false, default: "09:00"
      t.string :office_closes_at, null: false, default: "18:00"
      t.string :open_weekdays, null: false, default: "1,2,3,4,5,6"
      t.string :active_demo_scenario_key, null: false, default: "baseline"
      t.datetime :last_demo_data_action_at
      t.timestamps
    end

    create_table :availability_windows do |t|
      t.references :property, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :kind, null: false, default: "open"
      t.string :label
      t.text :notes
      t.timestamps
    end

    add_index :availability_windows, [:property_id, :starts_at, :ends_at], name: "index_availability_windows_on_property_and_range"
    add_index :availability_windows, :kind

    create_table :appointments do |t|
      t.references :property, null: false, foreign_key: true
      t.references :admin, foreign_key: true
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.string :customer_phone
      t.datetime :requested_time, null: false
      t.datetime :scheduled_at, null: false
      t.integer :duration_minutes, null: false, default: 45
      t.string :status, null: false, default: "pending"
      t.text :notes
      t.text :internal_notes
      t.string :public_reference, null: false
      t.string :access_token, null: false
      t.timestamps
    end

    add_index :appointments, :public_reference, unique: true
    add_index :appointments, :access_token, unique: true
    add_index :appointments, :customer_email
    add_index :appointments, [:status, :scheduled_at]

    create_table :appointment_events do |t|
      t.references :appointment, null: false, foreign_key: true
      t.references :admin, foreign_key: true
      t.string :event_type, null: false
      t.string :from_status
      t.string :to_status
      t.text :message
      t.json :metadata
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :appointment_events, :event_type

    create_table :notification_logs do |t|
      t.references :appointment, foreign_key: true
      t.string :recipient_email
      t.string :subject, null: false
      t.text :body_preview
      t.string :event_type, null: false
      t.string :status, null: false
      t.text :error_message
      t.json :metadata
      t.timestamps
    end

    add_index :notification_logs, :status

    create_table :demo_scenario_runs do |t|
      t.string :scenario_key
      t.string :action_type, null: false
      t.string :initiated_by_email
      t.string :source, null: false, default: "catalog"
      t.json :summary_data
      t.timestamps
    end

    add_index :demo_scenario_runs, :scenario_key
  end
end
