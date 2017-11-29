class CreateLeads < ActiveRecord::Migration[5.1]
  def change
    create_table :leads, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :lead_source_id
      t.uuid :lead_preferences_id
      t.string :title
      t.string :first_name
      t.string :last_name
      t.string :referral
      t.string :state
      t.text :notes
      t.datetime :first_comm
      t.datetime :last_comm

      t.timestamps
    end
  end
end
