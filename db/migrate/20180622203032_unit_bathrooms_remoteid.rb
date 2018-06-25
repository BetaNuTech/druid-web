class UnitBathroomsRemoteid < ActiveRecord::Migration[5.2]
  def change
    add_column :units, :remoteid, :string
    add_column :units, :bathrooms, :integer
    add_column :units, :occupancy, :string, default: 'vacant'
    add_column :units, :lease_status, :string, default: 'available'
    add_column :units, :available_on, :date
    add_column :units, :market_rent, :decimal, default: 0.0
    add_index :units, :remoteid
  end
end
