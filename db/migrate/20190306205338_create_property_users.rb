class CreatePropertyUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :property_users, id: :uuid do |t|
      t.uuid :property_id
      t.uuid :user_id
      t.integer :role
      t.timestamps
    end

    add_index :property_users, [:property_id, :user_id], unique: true
  end
end
