class AddDuplicateLeadsIndexOnLeadId < ActiveRecord::Migration[5.2]
  def self.up
    add_index :duplicate_leads, :lead_id
  end
  def self.down
    remove_index :duplicate_leads, :lead_id
  end
end
