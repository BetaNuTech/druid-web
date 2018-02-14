class CreateLeadActions < ActiveRecord::Migration[5.1]
  def change
    create_table :lead_actions, id: :uuid do |t|
      t.string :name
      t.string :description
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
