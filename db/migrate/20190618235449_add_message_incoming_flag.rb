class AddMessageIncomingFlag < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :incoming, :boolean
  end
end
