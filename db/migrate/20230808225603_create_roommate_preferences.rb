class CreateRoommatePreferences < ActiveRecord::Migration[6.1]
  def change
    create_table :roommate_preferences, id: :uuid do |t|
      t.references :roommate
      t.boolean :optout_email, default: false
      t.datetime :optout_email_date
      t.boolean :optin_sms, default: false
      t.datetime :optin_sms_date

      t.timestamps
    end
    add_index :roommate_preferences, :roommate_id
  end
end
