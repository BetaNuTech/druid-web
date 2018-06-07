class AddMessageReadStatus < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :read_at, :datetime
    add_column :messages, :read_by_user_id, :uuid
  end
end
