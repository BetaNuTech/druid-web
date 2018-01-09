class AddRoleIdToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :role_id, :uuid
  end
end
