class CreateEngagementPolicies < ActiveRecord::Migration[5.1]
  def change
    create_table :engagement_policies, id: :uuid do |t|
      t.uuid :property_id
      t.string :lead_state
      t.text :description
      t.integer :version, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :engagement_policies, [:active, :lead_state, :property_id, :version], name: 'covering'
  end
end
