class AddLeadDedupeIndex < ActiveRecord::Migration[5.2]
  def self.up
    add_index :leads, [:phone1, :phone2, :first_name, :last_name, :email], name: 'lead_dedupe_idx'
  end

  def self.down
    remove_index :leads, name: 'lead_dedupe_idx'
  end
end
