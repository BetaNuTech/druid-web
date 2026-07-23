class AddYardiSourceAuditToMarketingSources < ActiveRecord::Migration[6.1]
  def change
    add_column :marketing_sources, :yardi_source_missing, :boolean, default: false, null: false
    add_column :marketing_sources, :yardi_source_checked_at, :datetime
  end
end
