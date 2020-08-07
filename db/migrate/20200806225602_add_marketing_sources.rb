class AddMarketingSources < ActiveRecord::Migration[6.0]
  def change
    create_table :marketing_sources, id: :uuid do |t|
      t.boolean :active, default: true
      t.uuid :property_id, null: false
      t.uuid :lead_source_id
      t.string :name, null: false
      t.text :description
      t.string :tracking_code
      t.string :tracking_email
      t.string :tracking_number
      t.string :destination_number
      t.integer :fee_type, default: 0, null: false
      t.decimal :fee_rate, default: 0.0
      t.date :start_date, null: false
      t.date :end_date

      t.timestamps
    end

    add_index :marketing_sources, [:property_id, :name], unique: true
    add_index :marketing_sources, :tracking_number
    add_index :marketing_sources, :tracking_email
  end
end
