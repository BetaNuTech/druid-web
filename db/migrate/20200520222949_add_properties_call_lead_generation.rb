class AddPropertiesCallLeadGeneration < ActiveRecord::Migration[6.0]
  def change
    add_column :properties, :call_lead_generation, :boolean, default: true
  end
end
