class AddUserTeamroleId < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :teamrole_id, :uuid
    add_index :users, :teamrole_id
  end
end
