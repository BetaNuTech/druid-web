class AddHtmlToMessageTypes < ActiveRecord::Migration[5.1]
  def up
    add_column :message_types, :html, :boolean, default: false
    MessageType.where(name: 'Email').update_all(html: true)
  end

  def down
    remove_column :message_types, :html
  end
end
