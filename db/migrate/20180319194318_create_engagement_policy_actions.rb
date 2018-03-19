class CreateEngagementPolicyActions < ActiveRecord::Migration[5.1]
  def change
    create_table :engagement_policy_actions, id: :uuid do |t|
      t.uuid :engagement_policy_id
      t.uuid :lead_action_id
      t.text :description
      t.decimal :deadline
      t.integer :retry_count, default: 0
      t.decimal :retry_delay, default: 0.0
      t.string :retry_delay_multiplier, default: 'none'
      t.decimal :score, default: 1.0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :engagement_policy_actions, [:engagement_policy_id, :lead_action_id], name: "engagement_policy_covering"
  end
end
