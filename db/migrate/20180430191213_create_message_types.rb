class CreateMessageTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :message_types, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.timestamps
    end
  end
end
