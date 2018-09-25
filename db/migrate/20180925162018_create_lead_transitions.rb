class CreateLeadTransitions < ActiveRecord::Migration[5.2]
  def change
    create_table :lead_transitions, id: :uuid do |t|
      t.uuid :lead_id, null: false
      t.string :last_state, null: false
      t.string :current_state, null: false
      t.integer :classification
      t.text :memo

      t.timestamps
    end
    add_index :lead_transitions, :lead_id
  end
end
