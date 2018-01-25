class CreateUserProfiles < ActiveRecord::Migration[5.1]
  def change
    create_table :user_profiles, id: :uuid do |t|
      t.uuid :user_id
      t.string :name_prefix
      t.string :first_name
      t.string :last_name
      t.string :name_suffix
      t.string :slack
      t.string :cell_phone
      t.string :office_phone
      t.string :fax
      t.text :notes

      t.timestamps
    end
    add_index :user_profiles, :user_id, unique: true
  end
end
