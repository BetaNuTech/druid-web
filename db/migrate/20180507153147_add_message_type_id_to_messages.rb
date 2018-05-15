class AddMessageTypeIdToMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :message_type_id, :uuid
  end
end
