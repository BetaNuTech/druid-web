class AuditJsonb < ActiveRecord::Migration[5.2]
  def up
    Audited::Audit.delete_all
    change_column :audits, :audited_changes, :jsonb, using: 'audited_changes::text::jsonb'
  end
  def down
    change_column :audits, :audited_changes, :text
  end
end
