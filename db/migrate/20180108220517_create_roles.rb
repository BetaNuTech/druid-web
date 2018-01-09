class CreateRoles < ActiveRecord::Migration[5.1]
  def change
    create_table :roles, id: :uuid do |t|
      t.string :name
      t.string :slug
      t.text :description

      t.timestamps
    end
  end
end
