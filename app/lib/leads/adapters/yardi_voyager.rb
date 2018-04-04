module Leads
  module Adapters
    class YardiVoyager
      LEAD_SOURCE_SLUG = 'YardiVoyager'

      # Accepts a Hash
      #
      # Ex: { property_code: 'marble'}
      def initialize(params)
        @lead_source =  get_lead_source
        raise "Lead Adapter Error! LeadSource record for #{LEAD_SOURCE_SLUG} is missing!" if @lead_source.nil?
        @property_code = get_property_code(params)
        @property = property_for_listing_code(@property_code)
        @data = fetch(@property_code)
      end

      def parse
        # TODO
        leads = collection_from_guestcards(@data)
        ActiveRecord::Base.transaction do
          leads.each{|l| l.save}
        end
        return leads
      end

      private

      def collection_from_guestcards(guestcards)
        return guestcards.map{|guestcard| lead_from_guestcard(guestcard)}
      end

      def lead_from_guestcard(guestcard)
        # TODO
        lead = Lead.new
        preference = LeadPreference.new

        lead.remoteid = guestcard.prospect_id || guestcard.tenant_id
        lead.title = guestcard.name_prefix
        lead.first_name = guestcard.first_name
        lead.middle_name = guestcard.middle_name
        lead.last_name = guestcard.last_name
        unless guestcard.phones.nil?
          lead.phone1 = guestcard.phones.first.try(:last)
          lead.phone2 = guestcard.phones.last.try(:last) if guestcard.phones.size > 1
        end
        lead.email = guestcard.email
        lead.state = lead_state_for(guestcard)
        lead.priority = priority_from_state(lead.state)
        lead.notes = guestcard.summary

        preference.move_in = guestcard.expected_move_in || guestcard.actual_move_in
        preference.beds = guestcard.bedrooms
        preference.max_price = guestcard.rent unless guestcard.rent.nil?
        preference.notes = guestcard.preference_comment
        preference.raw_data = guestcard.summary

        lead.source = @lead_source
        lead.preference = preference
        lead.property = @property

        # TODO: Lead Events
        #

        return lead
      end

      def fetch(propertycode)
        return Yardi::Voyager::Api::GuestCards.new.getGuestCards(propertycode)
      end

      def lead_state_for(guestcard)
        record_type_state_map = {
          'applicant' => 'application',
          'approved_applicant' => 'approved',
          'future_resident' => 'movein',
          'prospect' => 'open' }
        state = record_type_state_map.fetch( guestcard.record_type, 'open' )
        return state
      end

      def priority_from_state(state)
        priority = 'urgent'
        case state
          when 'application'
            priority = 'high'
          when 'approved'
            priority = 'high'
          when 'movein'
            priority = 'high'
          when 'open'
            priority = 'urgent'
          else
            priority = 'urgent'
        end
        return priority
      end

      def get_property_code(params)
        return params[:property_code]
      end

      def get_lead_source
        return LeadSource.active.where(slug: LEAD_SOURCE_SLUG).first
      end

      def property_for_listing_code(listingcode)
        property = @lead_source.listings.active.where(code: listingcode).
          first.try(:property)
        Rails.logger.warn "Error in Leads::Adapters::YardiVoyager finding PropertyListing code '#{listingcode}'" if property.nil?
        return property
      end

    end
  end
end
