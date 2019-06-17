class AddRemoteidToLeadTransitions < ActiveRecord::Migration[5.2]
  def change
    add_column :lead_transitions, :remoteid, :string
  end
end
