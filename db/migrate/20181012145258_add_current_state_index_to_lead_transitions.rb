class AddCurrentStateIndexToLeadTransitions < ActiveRecord::Migration[5.2]
  def self.up
    add_index :lead_transitions, [:last_state, :current_state, :created_at], name: 'state_xtn'
  end

  def self.down
    remove_index :lead_transitions, name: 'state_xtn'
  end
end
