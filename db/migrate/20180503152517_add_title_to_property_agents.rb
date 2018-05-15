class AddTitleToPropertyAgents < ActiveRecord::Migration[5.1]
  def change
    add_column :property_agents, :title, :string
  end
end
