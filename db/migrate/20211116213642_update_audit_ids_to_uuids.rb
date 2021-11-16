class UpdateAuditIdsToUuids < ActiveRecord::Migration[6.1]
  def change
    remove_column :audits, :associated_id
    add_column :audits, :associated_id, :uuid
    remove_column :audits, :user_id
    add_column :audits, :user_id, :uuid
  end
end
