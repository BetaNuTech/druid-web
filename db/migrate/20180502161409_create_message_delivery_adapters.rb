class CreateMessageDeliveryAdapters < ActiveRecord::Migration[5.1]
  def change
    create_table :message_delivery_adapters, id: :uuid do |t|
      t.uuid :message_type_id, null: false
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :message_delivery_adapters, :message_type_id
    add_index :message_delivery_adapters, :slug, unique: true
  end
end
