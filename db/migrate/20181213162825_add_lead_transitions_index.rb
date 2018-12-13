class AddLeadTransitionsIndex < ActiveRecord::Migration[5.2]
  def self.up
    add_index :lead_transitions, [:last_state, :current_state]
  end
  def self.down
    remove_index :lead_transitions, [:last_state, :current_state]
  end
end
