class RenameCallcenterLeadSourceSlug < ActiveRecord::Migration[5.2]
  def change
    LeadSource.where(name: 'CallCenter').update_all(slug: 'CallCenter')
  end
end
