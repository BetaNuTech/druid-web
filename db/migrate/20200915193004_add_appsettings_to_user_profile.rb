class AddAppsettingsToUserProfile < ActiveRecord::Migration[6.0]
  def change
    add_column :user_profiles, :appsettings, :jsonb, default: {}

    UserProfile.where(signature_enabled: true).each do |profile|
      profile.switch_setting!(:message_signature, true)
    end
    remove_column :user_profiles, :signature_enabled

    UserProfile.where(monitor_all_messages: true).each do |profile|
      profile.switch_setting!(:message_web_notifications, true)
      profile.switch_setting!(:view_all_messages, true)
    end
    remove_column :user_profiles, :monitor_all_messages

  end
end
