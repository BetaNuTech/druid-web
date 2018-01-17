class AddPriorityToLeads < ActiveRecord::Migration[5.1]
  def change
    add_column :leads, :priority, :integer, default: 1
    add_index :leads, :priority

    Lead.update_all(priority: 1)
  end
end
