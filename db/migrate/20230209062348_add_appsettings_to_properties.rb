class AddAppsettingsToProperties < ActiveRecord::Migration[6.1]
  def change
    add_column :properties, :appsettings, :jsonb, default: {}

    Property.all.each do |property|
      begin
        property.repair_settings!
        property.switch_setting!(:lead_auto_welcome, true)
      rescue
        true
      end
    end
  end
end
