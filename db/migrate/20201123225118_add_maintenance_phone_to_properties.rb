class AddMaintenancePhoneToProperties < ActiveRecord::Migration[6.0]
  def change
    add_column :properties, :maintenance_phone, :string
  end
end
