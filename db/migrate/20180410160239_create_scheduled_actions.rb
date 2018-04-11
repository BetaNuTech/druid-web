class CreateScheduledActions < ActiveRecord::Migration[5.1]
  def change
    create_table :scheduled_actions, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :target_id
      t.string :target_type
      t.uuid :originator_id
      t.uuid :lead_action_id
      t.uuid :reason_id
      t.uuid :engagement_policy_action_id
      t.uuid :engagement_policy_action_compliance_id
      t.text :description
      t.datetime :completed_at
      t.string :state, default: 'pending'
      t.integer :attempt, default: 1

      t.timestamps
    end

    add_index :scheduled_actions, :user_id
    add_index :scheduled_actions, [:target_id, :target_type], name: 'scheduled_action_target'
    add_index :scheduled_actions, :originator_id
  end
end
