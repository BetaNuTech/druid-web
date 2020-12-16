module Properties
  module MarketingSources
    extend ActiveSupport::Concern

    class_methods do
      def property_info_for_incoming_number(number)
        clean_number = MarketingSource.format_phone(number)
        if (property = Property.active.where(phone: clean_number).first).present?
          marketing_source = nil
        else
          if (marketing_source = MarketingSource.where(tracking_number: clean_number).first).present?
            property = marketing_source.property
          end
        end

        return { dialed: clean_number, error: 'Not Found'} unless property

        lead_source = LeadSource.where(slug: 'CallCenter').first
        property_listing = PropertyListing.where(property_id: property.id, source_id: lead_source&.id).first

        {
          version: '1.0.0',
          date: Time.now,
          dialed: clean_number,
          property_id: property_listing&.code,
          name: property.name,
          main_number: property.phone,
          maintenance_number: property.maintenance_phone,
          hours: property.office_hours_today,
          open: property.office_open?,
          rings: 3,
          referrer: marketing_source&.name || 'Direct',
        }
      end

    end

    included do
      has_many :marketing_sources

      # Given an incoming number, return the matching MarketingSource name
      def referral_name_for_incoming_number(number)
        marketing_sources.where(tracking_number: number).first&.name
      end
    end
  end
end
