class CreateUserImpressions < ActiveRecord::Migration[6.0]
  def change
    create_table :user_impressions, id: :uuid do |t|
      t.uuid :user_id, required: true
      t.string :reference, required: true
      t.string :path
      t.string :referrer
      t.timestamps
    end

    add_index :user_impressions, [:user_id, :reference]
    add_index :user_impressions, [:reference, :created_at]
  end
end
