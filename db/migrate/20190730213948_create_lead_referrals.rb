class CreateLeadReferrals < ActiveRecord::Migration[5.2]
  def change
    create_table :lead_referrals, id: :uuid do |t|
      t.uuid :lead_id, null: false
      t.uuid :lead_referral_source_id
      t.uuid :referrable_id
      t.string :referrable_type
      t.text :note

      t.timestamps
    end

    add_index :lead_referrals, :lead_id
    add_index :lead_referrals, [:referrable_id, :referrable_type], name: "idx_referrable"

  end
end
