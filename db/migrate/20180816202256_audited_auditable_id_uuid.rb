class AuditedAuditableIdUuid < ActiveRecord::Migration[5.2]
  def change
    Audited::Audit.delete_all
    enable_extension 'uuid-ossp'
    change_column :audits, :auditable_id, :uuid, using: 'uuid_generate_v4()'
  end
end
