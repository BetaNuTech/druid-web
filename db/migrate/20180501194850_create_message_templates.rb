class CreateMessageTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :message_templates, id: :uuid do |t|
      t.uuid :message_type_id, null: false
      t.uuid :user_id
      t.string :name, null: false
      t.string :subject, null: false
      t.text :body, null: false

      t.timestamps
    end
    #add_index :message_templates, :message_type_id
  end
end
