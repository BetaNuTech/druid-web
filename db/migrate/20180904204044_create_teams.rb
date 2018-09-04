class CreateTeams < ActiveRecord::Migration[5.2]
  def change
    create_table :teams, id: :uuid do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
  end
end
