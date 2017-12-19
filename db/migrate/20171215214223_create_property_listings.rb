class CreatePropertyListings < ActiveRecord::Migration[5.1]
  def change
    create_table :property_listings, id: :uuid do |t|
      t.string :code
      t.string :description
      t.uuid :property_id
      t.uuid :source_id
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :property_listings, [:active, :code]
    add_index :property_listings, [:property_id, :source_id, :active]
  end
end
