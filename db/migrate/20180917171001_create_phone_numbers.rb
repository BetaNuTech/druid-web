class CreatePhoneNumbers < ActiveRecord::Migration[5.2]
  def change
    create_table :phone_numbers, id: :uuid do |t|
      t.string :name
      t.string :number
      t.string :prefix, default: "1"
      t.integer :category, default: 0
      t.integer :availability, default: 0
      t.uuid :phoneable_id
      t.string :phoneable_type
      t.timestamps
    end

    add_index :phone_numbers, [:phoneable_type, :phoneable_id]
    add_index :phone_numbers, [:phoneable_type, :phoneable_id, :name], unique: true
  end
end
