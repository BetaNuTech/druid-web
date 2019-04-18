class AddSharedToMessageTemplates < ActiveRecord::Migration[5.2]
  def self.up
    add_column :message_templates, :shared, :boolean, default: true
    add_index :message_templates, [:shared, :user_id]
  end

  def self.down
    remove_index :message_templates, [:shared, :user_id]
    remove_column :message_templates, :shared
  end
end
