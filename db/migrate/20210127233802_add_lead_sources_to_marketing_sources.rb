class AddLeadSourcesToMarketingSources < ActiveRecord::Migration[6.0]
  def change
    add_column :marketing_sources, :phone_lead_source_id, :uuid
    add_column :marketing_sources, :email_lead_source_id, :uuid
  end
end
