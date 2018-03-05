class CreateResidentDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :resident_details, id: :uuid do |t|
      t.uuid :resident_id
      t.string :phone1
      t.string :phone1_type
      t.string :phone1_tod
      t.string :phone2
      t.string :phone2_type
      t.string :phone2_tod
      t.string :email
      t.string :encrypted_ssn
      t.string :encrypted_ssn_iv
      t.string :id_number
      t.string :id_state

      t.timestamps
    end
    add_index :resident_details, :resident_id
  end
end
