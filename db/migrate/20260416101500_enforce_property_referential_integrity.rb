class EnforcePropertyReferentialIntegrity < ActiveRecord::Migration[8.1]
  def up
    cleanup_orphan_property_graph!
    cleanup_orphans!(:photos, :property_id, :properties)
    cleanup_orphans!(:floor_plans, :property_id, :properties)
    cleanup_orphans!(:viewing_times, :property_id, :properties)

    change_column_null :properties, :user_id, false
    add_foreign_key :properties, :users unless foreign_key_exists?(:properties, :users)

    change_column_null :photos, :property_id, false
    add_foreign_key :photos, :properties unless foreign_key_exists?(:photos, :properties)

    change_column_null :floor_plans, :property_id, false
    add_foreign_key :floor_plans, :properties unless foreign_key_exists?(:floor_plans, :properties)

    change_column_null :viewing_times, :property_id, false
    add_foreign_key :viewing_times, :properties unless foreign_key_exists?(:viewing_times, :properties)
  end

  def down
    remove_foreign_key :viewing_times, :properties if foreign_key_exists?(:viewing_times, :properties)
    change_column_null :viewing_times, :property_id, true

    remove_foreign_key :floor_plans, :properties if foreign_key_exists?(:floor_plans, :properties)
    change_column_null :floor_plans, :property_id, true

    remove_foreign_key :photos, :properties if foreign_key_exists?(:photos, :properties)
    change_column_null :photos, :property_id, true

    remove_foreign_key :properties, :users if foreign_key_exists?(:properties, :users)
    change_column_null :properties, :user_id, true
  end

  private

  def cleanup_orphan_property_graph!
    property_ids = select_values(<<~SQL.squish)
      SELECT properties.id
      FROM properties
      LEFT JOIN users ON users.id = properties.user_id
      WHERE properties.user_id IS NULL OR users.id IS NULL
    SQL

    return if property_ids.empty?

    say "Removing #{property_ids.size} orphaned properties before adding constraints"

    appointment_ids = select_values("SELECT id FROM appointments WHERE property_id IN (#{quoted_list(property_ids)})")
    enquiry_ids = select_values("SELECT id FROM enquiries WHERE property_id IN (#{quoted_list(property_ids)})")
    offer_ids = select_values("SELECT id FROM offers WHERE property_id IN (#{quoted_list(property_ids)})")
    rental_application_ids = select_values("SELECT id FROM rental_applications WHERE property_id IN (#{quoted_list(property_ids)})")

    delete_by_ids(:notification_logs, :appointment_id, appointment_ids)
    delete_by_ids(:notification_logs, :enquiry_id, enquiry_ids)
    delete_by_ids(:appointment_events, :appointment_id, appointment_ids)
    delete_by_ids(:offer_events, :offer_id, offer_ids)
    delete_by_ids(:rental_application_events, :rental_application_id, rental_application_ids)

    delete_by_ids(:photos, :property_id, property_ids)
    delete_by_ids(:floor_plans, :property_id, property_ids)
    delete_by_ids(:viewing_times, :property_id, property_ids)
    delete_by_ids(:availability_windows, :property_id, property_ids)
    delete_by_ids(:appointments, :property_id, property_ids)
    delete_by_ids(:enquiries, :property_id, property_ids)
    delete_by_ids(:offers, :property_id, property_ids)
    delete_by_ids(:rental_applications, :property_id, property_ids)
    delete_by_ids(:property_documents, :property_id, property_ids)
    delete_by_ids(:audit_logs, :property_id, property_ids)
    delete_by_ids(:saved_properties, :property_id, property_ids)
    delete_by_ids(:properties, :id, property_ids)
  end

  def cleanup_orphans!(table, foreign_key, parent_table)
    deleted = delete(<<~SQL.squish)
      DELETE FROM #{quote_table_name(table)}
      WHERE #{quote_column_name(foreign_key)} IS NULL
         OR NOT EXISTS (
           SELECT 1
           FROM #{quote_table_name(parent_table)}
           WHERE #{quote_table_name(parent_table)}.id = #{quote_table_name(table)}.#{quote_column_name(foreign_key)}
         )
    SQL

    say "Removed #{deleted} orphaned #{table}" if deleted.positive?
  end

  def delete_by_ids(table, column, ids)
    return if ids.empty?

    delete <<~SQL.squish
      DELETE FROM #{quote_table_name(table)}
      WHERE #{quote_column_name(column)} IN (#{quoted_list(ids)})
    SQL
  end

  def quoted_list(values)
    values.map { |value| connection.quote(value) }.join(", ")
  end
end
