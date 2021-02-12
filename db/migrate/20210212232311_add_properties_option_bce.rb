class AddPropertiesOptionBce < ActiveRecord::Migration[6.0]
  def change
    add_column :properties, :voice_menu_enabled, :boolean, default: false
  end
end
