class UpgradeMarketingSourceData < ActiveRecord::Migration[6.0]
  def change
    MarketingSource.all.each do |ms|
      original_source = ms.lead_source
      next unless original_source

      case original_source.slug
      when 'Arrowtel'
        ms.phone_lead_source = original_source
        ms.lead_source = nil
      when 'Cloudmailin'
        ms.email_lead_source = original_source
        ms.lead_source = nil
      end
      ms.save
    end
  end
end
