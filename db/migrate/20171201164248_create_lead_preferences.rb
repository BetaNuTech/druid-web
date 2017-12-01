class CreateLeadPreferences < ActiveRecord::Migration[5.1]
  def change
    create_table :lead_preferences, id: :uuid do |t|
      t.uuid :lead_id
      t.integer :min_area
      t.integer :max_area
      t.decimal :min_price
      t.decimal :max_price
      t.datetime :move_in
      t.decimal :baths
      t.boolean :pets
      t.boolean :smoker
      t.boolean :washerdryer
      t.text :notes

      t.timestamps
    end

    remove_column :leads, :lead_preferences_id
  end
end
