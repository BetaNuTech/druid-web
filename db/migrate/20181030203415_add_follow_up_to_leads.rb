class AddFollowUpToLeads < ActiveRecord::Migration[5.2]
  def change
    add_column :leads, :follow_up_at, :datetime
    add_index :leads, :follow_up_at
  end
end
