class CreateErrorAlerts < ActiveRecord::Migration[6.1]
  def change
    # One row per distinct error (exception class + where it was raised), so a
    # repeating error posts to #bluesky-errors once per window instead of once
    # per occurrence. See ErrorAlert.
    create_table :error_alerts, id: :uuid do |t|
      t.string :fingerprint, null: false
      t.datetime :last_posted_at
      t.integer :suppressed_count, null: false, default: 0

      t.timestamps
    end

    add_index :error_alerts, :fingerprint, unique: true
  end
end
