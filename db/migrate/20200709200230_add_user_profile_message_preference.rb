class AddUserProfileMessagePreference < ActiveRecord::Migration[6.0]
  def change
    add_column :user_profiles, :monitor_all_messages, :boolean, default: false
  end
end
