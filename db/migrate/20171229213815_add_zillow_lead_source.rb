class AddZillowLeadSource < ActiveRecord::Migration[5.1]
  def change
    LeadSource.create!(name: 'Zillow', slug: 'Zillow', active: true)
  end
end
