class RemovePropertyAgents < ActiveRecord::Migration[5.2]
  def change
    drop_table :property_agents
  end
end
