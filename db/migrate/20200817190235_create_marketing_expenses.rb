class CreateMarketingExpenses < ActiveRecord::Migration[6.0]
  def change
    create_table :marketing_expenses, id: :uuid do |t|
      t.uuid :property_id, null: false
      t.uuid :marketing_source_id, null: false
      t.string :invoice
      t.text :description
      t.decimal :fee_total, null: false
      t.integer :fee_type, null: false, default: 0
      t.integer :quantity, null: false, default: 1
      t.date :start_date, null: false
      t.date :end_date

      t.timestamps

      t.index [ :property_id, :marketing_source_id, :start_date ], name: 'query_idx'
    end
  end
end
