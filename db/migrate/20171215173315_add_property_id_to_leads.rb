class AddPropertyIdToLeads < ActiveRecord::Migration[5.1]
  def change
    add_column :leads, :property_id, :uuid
  end
end
