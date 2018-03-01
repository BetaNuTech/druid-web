class CreateResidents < ActiveRecord::Migration[5.1]
  def change
    create_table :residents, id: :uuid do |t|
      t.uuid :lead_id
      t.uuid :property_id
      t.uuid :unit_id
      t.string :residentid
      t.string :status
      t.date :dob
      t.string :title
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :country

      t.timestamps
    end
    add_index :residents, [:property_id, :status, :unit_id]
    add_index :residents, :residentid, unique: true
  end
end
