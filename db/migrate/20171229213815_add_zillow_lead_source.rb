class AddZillowLeadSource < ActiveRecord::Migration[5.1]
  def change
    # Completely bypass the model to avoid auditing issues
    execute <<-SQL
      INSERT INTO lead_sources (id, name, slug, active, created_at, updated_at) 
      VALUES (gen_random_uuid(), 'Zillow', 'Zillow', true, now(), now())
    SQL
  end
end
