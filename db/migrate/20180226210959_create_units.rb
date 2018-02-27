class CreateUnits < ActiveRecord::Migration[5.1]
  def change
    create_table :units, id: :uuid do |t|
      t.uuid :property_id
      t.uuid :unit_type_id
      t.uuid :rental_type_id
      t.string :unit
      t.integer :floor
      t.integer :sqft
      t.integer :bedrooms
      t.text :description
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :country

      t.timestamps
    end
    add_index :units, [:property_id, :unit], unique: true
  end
end
