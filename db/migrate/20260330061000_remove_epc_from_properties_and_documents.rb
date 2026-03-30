class RemoveEpcFromPropertiesAndDocuments < ActiveRecord::Migration[8.1]
  class MigrationPropertyDocument < ActiveRecord::Base
    self.table_name = "property_documents"
  end

  def up
    if table_exists?(:property_documents)
      say_with_time "Removing EPC property documents" do
        MigrationPropertyDocument.where(category: "epc").delete_all
      end
    end

    remove_column :properties, :epc_rating, :string if column_exists?(:properties, :epc_rating)
  end

  def down
    add_column :properties, :epc_rating, :string unless column_exists?(:properties, :epc_rating)
  end
end
