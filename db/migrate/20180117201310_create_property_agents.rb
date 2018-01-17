class CreatePropertyAgents < ActiveRecord::Migration[5.1]
  def change
    create_table :property_agents, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :property_id
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :property_agents, [:user_id, :property_id], unique: true
  end
end
