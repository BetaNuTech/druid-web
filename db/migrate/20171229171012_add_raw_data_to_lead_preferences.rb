class AddRawDataToLeadPreferences < ActiveRecord::Migration[5.1]
  def change
    add_column :lead_preferences, :raw_data, :text
  end
end
