class AddOptoutEmailToLeadPreferences < ActiveRecord::Migration[5.2]
  def change
    add_column :lead_preferences, :optout_email, :boolean, default: false
    add_column :lead_preferences, :optout_email_date, :datetime
  end
end
