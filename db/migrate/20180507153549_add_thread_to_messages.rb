class AddThreadToMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :thread, :uuid
  end
end
