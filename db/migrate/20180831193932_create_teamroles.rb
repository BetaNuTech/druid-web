class CreateTeamroles < ActiveRecord::Migration[5.2]
  def self.up
    create_table :teamroles, id: :uuid do |t|
      t.string :name
      t.string :slug
      t.string :description
      t.timestamps
    end
    add_index :teamroles, :slug, unique: true
  end
  
  def self.down
    drop_table :teamroles
  end
end
