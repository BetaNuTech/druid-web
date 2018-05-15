class AddThreadToMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :threadid, :string
    add_index :messages, :threadid
  end
end
