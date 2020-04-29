class AddSmsOptinLeadPreferences < ActiveRecord::Migration[6.0]
  def change
    add_column :lead_preferences, :optin_sms, :boolean, default: false
    add_column :lead_preferences, :optin_sms_date, :datetime
  end
end
