class CreateMessageDeliveries < ActiveRecord::Migration[5.1]
  def change
    create_table :message_deliveries, id: :uuid do |t|
      t.uuid :message_id
      t.uuid :message_type_id
      t.integer :attempt
      t.datetime :attempted_at
      t.string :status
      t.text :log
      t.datetime :delivered_at
      t.timestamps
    end
    add_index :message_deliveries, :message_id
  end
end
