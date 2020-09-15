class CreateFeatures < ActiveRecord::Migration[6.0]
  def change
    unless table_exists?(:flipflop_features)
      create_table :flipflop_features do |t|
        t.string :key, null: false
        t.boolean :enabled, null: false, default: false

        t.timestamps null: false
      end
    end
  end
end
