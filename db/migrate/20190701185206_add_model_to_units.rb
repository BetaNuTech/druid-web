class AddModelToUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :units, :model, :boolean, default: false
  end
end
