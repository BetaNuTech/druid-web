class RenameDruidSource < ActiveRecord::Migration[5.2]
  def self.up
    if (druid_source = LeadSource.where(name: "Druid Webapp").first).present?
      druid_source.name = "BlueSky Webapp"
      druid_source.save
    end
    LeadSource.where(slug: "Druid").update_all(slug: "Bluesky")
  end

  def self.down
    if (druid_source = LeadSource.where(name: "BlueSky Webapp").first).present?
      druid_source.name = "Druid Webapp"
      druid_source.save
    end
    LeadSource.where(slug: "Bluesky").update_all(slug: "Druid")
  end
end
