class CreateRoommates < ActiveRecord::Migration[6.0]
  def change
    create_table :roommates, id: :uuid do |t|
      t.uuid :lead_id
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :email
      t.integer :relationship, default: 0
      t.boolean :sms_allowed, default: false
      t.boolean :email_allowed, default: true
      t.integer :occupancy, default: 0
      t.string :remoteid
      t.text :notes
      t.timestamps
    end
  end
end
