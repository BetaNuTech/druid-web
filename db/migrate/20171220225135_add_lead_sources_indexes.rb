class AddLeadSourcesIndexes < ActiveRecord::Migration[5.1]
  def change
    add_index :lead_sources, [:active, :api_token]
  end
end
