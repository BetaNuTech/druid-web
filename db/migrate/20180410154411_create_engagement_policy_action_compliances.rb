class CreateEngagementPolicyActionCompliances < ActiveRecord::Migration[5.1]
  def change
    create_table :engagement_policy_action_compliances, id: :uuid do |t|
      t.uuid :scheduled_action_id
      t.uuid :user_id
      t.string :state, default: 'pending'
      t.datetime :expires_at
      t.datetime :completed_at
      t.decimal :score
      t.text :memo

      t.timestamps
    end

    add_index :engagement_policy_action_compliances, [:user_id, :scheduled_action_id], name: "epac_user_id_sa_id"
    add_index :engagement_policy_action_compliances, :state, name: "epac_state"
    add_index :engagement_policy_action_compliances, :expires_at, name: "epac_expires_at"
  end
end
