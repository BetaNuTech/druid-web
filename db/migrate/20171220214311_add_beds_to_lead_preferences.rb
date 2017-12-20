class AddBedsToLeadPreferences < ActiveRecord::Migration[5.1]
  def change
    add_column :lead_preferences, :beds, :integer
  end
end
