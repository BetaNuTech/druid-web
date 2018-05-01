class CreateMessageTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :message_types, id: :uuid do |t|
      t.string :name
      t.text :description
      t.boolean :active
      t.timestamps
    end
  end
end
