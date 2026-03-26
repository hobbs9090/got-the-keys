class CreateEnquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :enquiries do |t|
      t.references :property, null: false, foreign_key: true
      t.references :admin, null: true, foreign_key: true
      t.string :lead_reference, null: false
      t.string :status, null: false, default: "new"
      t.string :source_type, null: false, default: "general_enquiry"
      t.string :customer_name, null: false
      t.string :customer_email
      t.string :customer_phone
      t.text :message, null: false
      t.text :internal_notes
      t.boolean :spam, null: false, default: false
      t.string :spam_reason
      t.datetime :contacted_at
      t.timestamps
    end

    add_index :enquiries, :lead_reference, unique: true
    add_index :enquiries, :status
    add_index :enquiries, :source_type
    add_index :enquiries, :spam
    add_index :enquiries, %i[property_id created_at]

    add_reference :notification_logs, :enquiry, foreign_key: true
  end
end
