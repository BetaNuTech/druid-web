class CreateLeadReferralSources < ActiveRecord::Migration[5.2]
  def change
    create_table :lead_referral_sources, id: :uuid do |t|
      t.string :name

      t.timestamps
    end
  end
end
