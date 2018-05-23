class AddUnitTypeToLeadPreference < ActiveRecord::Migration[5.1]
  def change
    add_column :lead_preferences, :unit_type_id, :uuid
  end
end
