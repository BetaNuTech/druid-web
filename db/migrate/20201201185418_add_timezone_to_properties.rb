class AddTimezoneToProperties < ActiveRecord::Migration[6.0]
  def change
    add_column :properties, :timezone, :string, default: 'UTC', null: false
  end
end
