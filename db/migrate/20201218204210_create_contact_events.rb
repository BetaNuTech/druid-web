class CreateContactEvents < ActiveRecord::Migration[6.0]
  def self.up
    drop_table :contact_events if table_exists?(:contact_events)

    create_table :contact_events, id: :uuid do |t|
      t.uuid :lead_id, null: false
      t.uuid :user_id, null: false
      t.uuid :article_id
      t.string :article_type
      t.string :description
      t.datetime :timestamp, null: false 
      t.boolean :first_contact, default: false, null: false
      t.integer :lead_time, default: 0, null: false
      t.timestamps
    end

    add_index :contact_events, [:first_contact, :timestamp], name: :contact_events_contact_and_timestamp
    add_index :contact_events, [:lead_id, :user_id, :first_contact, :timestamp], name: :contact_events_general_idx
  end
end
