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
        main_number = property.phone
        maintenance_number = ( property.maintenance_phone || '' ).gsub(' ','').empty? ? property.phone : property.maintenance_phone
        leasing_number = ( property.leasing_phone || '' ).gsub(' ','').empty? ? property.phone : property.leasing_phone

        {
          version: '1.0.0',
          date: DateTime.current,
          dialed: clean_number,
          property_id: property_listing&.code,
          name: property.name,
          main_number: main_number,
          maintenance_number: maintenance_number,
          leasing_number: leasing_number,
          hours: property.office_hours_today,
          open: property.office_open?,
          rings: 3,
          referrer: marketing_source&.name || 'Direct',
          menu_enabled: property.voice_menu_enabled
        }
      end

    end

    included do
      has_many :marketing_sources

      # Given an incoming number, return the matching MarketingSource name
      def referral_name_for_incoming_number(number)
        marketing_sources.where(tracking_number: number).first&.name
      end

      # The main line (Property#phone) is what call routing resolves an
      # incoming call to, and it is the fallback destination whenever the
      # leasing or maintenance number is blank (see
      # property_info_for_incoming_number). Without it, calls placed to a
      # marketing tracking number have no number to forward to and the
      # resulting phone lead cannot be attributed to this property.
      def main_line_missing?
        phone.blank?
      end

      # True when marketing tracking numbers are in use but the main line
      # they depend on has not been set.
      def marketing_tracking_numbers_without_main_line?
        main_line_missing? && marketing_sources.where.not(tracking_number: [nil, '']).exists?
      end
    end
  end
end
