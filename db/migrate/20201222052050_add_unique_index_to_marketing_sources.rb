class AddUniqueIndexToMarketingSources < ActiveRecord::Migration[6.0]
  def up
    change_column :marketing_sources, :tracking_number, :string, unique: true
  end
  def down
    change_column :marketing_sources, :tracking_number, :string, unique: false
  end
end
