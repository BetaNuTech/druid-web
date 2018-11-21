class CreateDuplicateLeads < ActiveRecord::Migration[5.2]
  def self.up
    create_table :duplicate_leads, id: :uuid do |t|
      t.uuid :reference_id
      t.uuid :lead_id
    end
    add_index :duplicate_leads, :reference_id
    add_index :duplicate_leads, [:reference_id, :lead_id], unique: true
  end

  def self.down
    drop_table :duplicate_leads
  end
end
