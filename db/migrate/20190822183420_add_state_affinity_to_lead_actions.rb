class AddStateAffinityToLeadActions < ActiveRecord::Migration[5.2]
  def self.up
    add_column :lead_actions, :state_affinity, :string, default: 'all'
    add_index :lead_actions, :state_affinity
  end

  def self.down
    remove_index :lead_actions, :state_affinity
    remove_column :lead_actions, :state_affinity
  end
end
