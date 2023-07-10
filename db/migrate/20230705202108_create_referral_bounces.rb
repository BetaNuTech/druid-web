class CreateReferralBounces < ActiveRecord::Migration[6.1]
  def change
    create_table :referral_bounces, id: :uuid do |t|
      t.references :property, null: false, foreign_key: true, type: :uuid
      t.string :propertycode, null: false
      t.string :campaignid, null: false
      t.string :trackingid
      t.string :referer

      t.timestamps
    end
  end
end
