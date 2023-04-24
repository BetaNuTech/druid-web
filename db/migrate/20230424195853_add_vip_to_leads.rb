class AddVipToLeads < ActiveRecord::Migration[6.1]
  def change
    add_column :leads, :vip, :boolean, default: false
    add_index :leads, [:property_id, :state, :vip], name: 'idx_leads_vip'
  end
end
