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
        # main_number is the number the call center forwards to, so a tracking
        # number's own destination goes there. See doc/property_call_routing.md.
        main_number = marketing_source&.destination_number.presence || property.phone
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

      after_update :move_tracking_destinations_with_main_line, if: :saved_change_to_phone?

      # Given an incoming number, return the matching MarketingSource name
      def referral_name_for_incoming_number(number)
        marketing_sources.where(tracking_number: number).first&.name
      end

      # A destination still on the old main line was following it rather than
      # overriding it, so it moves too. Otherwise calls to those tracking
      # numbers would keep forwarding to the retired line.
      def move_tracking_destinations_with_main_line
        old_phone, new_phone = saved_change_to_phone
        return if old_phone.blank?

        marketing_sources.where(destination_number: old_phone).update_all(destination_number: new_phone.presence)
      end
    end
  end
end
