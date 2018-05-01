class CreateMessageTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :message_templates, id: :uuid do |t|
      t.uuid :message_type_id
      t.uuid :user_id
      t.string :name
      t.string :subject
      t.text :body

      t.timestamps
    end
    add_index :message_templates, :message_type_id
  end
end
