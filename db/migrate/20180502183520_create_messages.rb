class CreateMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :messages, id: :uuid do |t|
      t.uuid :messageable_id
      t.string :messageable_type
      t.uuid :user_id, null: false
      t.string :state, null: false, default: 'draft'
      t.string :senderid, null: false
      t.string :recipientid, null: false
      t.uuid :message_template_id
      t.string :subject, null: false
      t.text :body, null: false
      t.datetime :delivered_at
      t.timestamps
    end

    add_index :messages, [:messageable_type, :messageable_id], name: "message_messageable"
    add_index :messages, :user_id
    add_index :messages, :state
  end
end
