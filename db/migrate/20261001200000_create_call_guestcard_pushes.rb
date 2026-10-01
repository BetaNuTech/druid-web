class CreateCallGuestcardPushes < ActiveRecord::Migration[6.1]
  def change
    # One row per BlueConnect call lead created while
    # CALL_LEAD_GUESTCARD_PUSH_ENABLED is on: the work queue for
    # Leads::CallGuestcardPusher, and the record of how each call was matched
    # or pushed to a Yardi guest card. See doc/call_lead_guestcard_push.md.
    create_table :call_guestcard_pushes, id: :uuid do |t|
      t.uuid :lead_id, null: false
      t.uuid :property_id, null: false
      t.string :phone
      t.string :referral
      t.string :status, null: false, default: 'pending'
      t.string :yardi_prospect_id
      t.string :yardi_source
      t.string :source_fix_status
      t.integer :attempts, null: false, default: 0
      t.text :last_error
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :call_guestcard_pushes, :lead_id, unique: true
    add_index :call_guestcard_pushes, %i[property_id phone]
    add_index :call_guestcard_pushes, :status
    add_foreign_key :call_guestcard_pushes, :leads, on_delete: :cascade
    add_foreign_key :call_guestcard_pushes, :properties, on_delete: :cascade
  end
end
