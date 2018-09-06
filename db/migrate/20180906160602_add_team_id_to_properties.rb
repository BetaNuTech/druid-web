class AddTeamIdToProperties < ActiveRecord::Migration[5.2]
  def change
    add_column :properties, :team_id, :uuid
    add_index :properties, :team_id
  end
end
