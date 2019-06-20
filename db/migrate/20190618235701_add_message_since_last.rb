class AddMessageSinceLast < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :since_last, :integer
  end
end
