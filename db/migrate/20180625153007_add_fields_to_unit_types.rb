class AddFieldsToUnitTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :unit_types, :remoteid, :string
    add_column :unit_types, :bathrooms, :integer
    add_column :unit_types, :bedrooms, :integer
    add_column :unit_types, :market_rent, :decimal, default: 0.0
    add_index :unit_types, :remoteid
  end
end
