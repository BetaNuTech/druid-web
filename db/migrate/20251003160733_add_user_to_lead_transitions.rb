class AddUserToLeadTransitions < ActiveRecord::Migration[6.1]
  def change
    add_reference :lead_transitions, :user, null: true, foreign_key: true, type: :uuid
  end
end
