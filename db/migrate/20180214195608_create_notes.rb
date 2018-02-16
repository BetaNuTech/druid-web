class CreateNotes < ActiveRecord::Migration[5.1]
  def change
    create_table :notes, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :lead_action_id
      t.uuid :reason_id
      t.uuid :notable_id
      t.string :notable_type
      t.text :content

      t.timestamps
    end

    add_index :notes, [:user_id, :notable_id, :notable_type]
  end
end
