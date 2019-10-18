class AddNotificationAttributesToScheduledActions < ActiveRecord::Migration[6.0]
  def change
    add_column :scheduled_actions, :notify, :boolean, default: false
    add_column :scheduled_actions, :notified_at, :datetime
    add_column :scheduled_actions, :notification_message, :text
    add_index :scheduled_actions, [:notify, :notified_at], name: 'notification_idx'
  end
end
