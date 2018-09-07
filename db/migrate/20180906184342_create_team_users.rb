class CreateTeamUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :team_users, id: :uuid do |t|
      t.uuid :team_id
      t.uuid :user_id
      t.uuid :teamrole_id
      t.timestamps
    end
    add_index :team_users, :user_id, unique: true
  end
end
