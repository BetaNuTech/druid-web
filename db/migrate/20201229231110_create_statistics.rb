class CreateStatistics < ActiveRecord::Migration[6.0]
  def change
    create_table :statistics, id: :uuid do |t|
      t.integer :fact, null: false
      t.uuid :quantifiable_id, null: false
      t.string :quantifiable_type, null: false
      t.integer :resolution, null: false, default: 1440
      t.decimal :value, null: false
      t.datetime :time_start, null: false
      t.timestamps
    end

    add_index :statistics, [:fact, :quantifiable_id, :quantifiable_type, :resolution, :time_start], name: :statistics_general_idx, unique: true
    add_index :statistics, :created_at
  end
end
