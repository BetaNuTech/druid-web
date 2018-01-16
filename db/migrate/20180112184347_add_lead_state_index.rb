class AddLeadStateIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :leads, :state
  end
end
