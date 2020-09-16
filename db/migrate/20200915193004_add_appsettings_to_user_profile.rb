class AddAppsettingsToUserProfile < ActiveRecord::Migration[6.0]
  def change
    add_column :user_profiles, :appsettings, :jsonb, default: {}

    UserProfile.all.each do |profile|
      profile.switch_setting!(:message_signature, true) if profile.signature_enabled?
      profile.switch_setting!(:view_all_messages, true) if profile.monitor_all_messages?
      profile.switch_setting!(:message_web_notifications, true)
      profile.switch_setting!(:lead_web_notifications, true)
    end

    remove_column :user_profiles, :signature_enabled
    remove_column :user_profiles, :monitor_all_messages
  end
end
