class AddColumnsToUnitTypes < ActiveRecord::Migration[5.1]
  def change
    add_column :unit_types, :description, :text
    add_column :unit_types, :property_id, :uuid
    add_index :unit_types, [:property_id, :name], unique: true
  end
end
