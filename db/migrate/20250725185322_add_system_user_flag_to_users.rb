class AddSystemUserFlagToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :system_user, :boolean, default: false, null: false
    add_index :users, :system_user, where: "system_user IS TRUE", unique: true
  end
end