class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.string :image_filename
      t.references :property, index: true

      t.timestamps
    end
  end
end
