class AddSystemToLeadActions < ActiveRecord::Migration[6.1]
  def change
    add_column :lead_actions, :is_system, :boolean, default: false
  end
end
