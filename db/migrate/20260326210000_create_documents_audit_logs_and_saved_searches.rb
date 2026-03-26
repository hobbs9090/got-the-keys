class CreateDocumentsAuditLogsAndSavedSearches < ActiveRecord::Migration[8.1]
  def change
    create_table :property_documents do |t|
      t.references :property, null: false, foreign_key: true
      t.string :title, null: false
      t.string :file_name, null: false
      t.string :category, null: false
      t.string :visibility, null: false, default: "private"
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :property_documents, [:property_id, :position]
    add_index :property_documents, :visibility
    add_index :property_documents, :category

    create_table :audit_logs do |t|
      t.references :property, foreign_key: true
      t.references :admin, foreign_key: true
      t.references :auditable, polymorphic: true
      t.string :action, null: false
      t.string :actor_label
      t.text :message, null: false
      t.json :metadata
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :audit_logs, :action
    add_index :audit_logs, [:property_id, :occurred_at]

    create_table :saved_searches do |t|
      t.string :email, null: false
      t.string :locale, null: false, default: "en"
      t.string :sale_status
      t.string :search_query
      t.string :town_city
      t.integer :min_bedrooms
      t.integer :min_price
      t.integer :max_price
      t.string :sort
      t.boolean :alerts_enabled, null: false, default: true
      t.timestamps
    end

    add_index :saved_searches, :email
    add_index :saved_searches, :sale_status
    add_index :saved_searches, :town_city
    add_index :saved_searches, :alerts_enabled
  end
end
