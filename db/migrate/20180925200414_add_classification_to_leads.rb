class AddClassificationToLeads < ActiveRecord::Migration[5.2]
  def change
    add_column :leads, :classification, :integer
    add_index :leads, :classification
  end
end
