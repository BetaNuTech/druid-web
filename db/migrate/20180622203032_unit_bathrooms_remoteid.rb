class UnitBathroomsRemoteid < ActiveRecord::Migration[5.2]
  def change
    add_column :units, :remoteid, :string
    add_column :units, :bathrooms, :integer
    add_index :units, :remoteid
  end
end
