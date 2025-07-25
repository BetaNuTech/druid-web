class AddSystemUserFlagToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :system_user, :boolean, default: false, null: false
    add_index :users, :system_user, where: "system_user = true", unique: true
  end
end