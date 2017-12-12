class CreateProperties < ActiveRecord::Migration[5.1]
  def change
    create_table :properties, id: :uuid do |t|
      t.string :name
      t.string :address1
      t.string :address2
      t.string :address3
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.string :organization
      t.string :contact_name
      t.string :phone
      t.string :fax
      t.string :email
      t.integer :units
      t.text :notes

      t.timestamps
    end
  end
end
