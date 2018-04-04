module Leads
  module Adapters
    class YardiVoyager
      LEAD_SOURCE_SLUG = 'YardiVoyager'

      # Accepts a Hash
      #
      # Ex: { property_code: 'marble'}
      def initialize(params)
        # TODO
        @property_code = get_property_code(params)
        @data = parse(fetch(@property_code))
      end

      def parse
        # TODO
        return []
      end

      private

      def collection_from_guestcards
        return []
      end

      def lead_from_guestcard(guestcard)
        lead = Lead.new

        lead.title = guestcard.name_prefix
        lead.first_name = guestcard.first_name
        lead.last_name = guestcard.last_name
        lead.remoteid = guestcard.prospect_id || guestcard.tenant_id
        lead.phone1 = guestcard.phones.first.try(:last)
        lead.phone2 = guestcard.phones.last.try(:last) if guestcard.phones.size > 1
        lead.email = guestcard.email

        return lead
      end

      def fetch(propertycode)
        return Yardi::Voyager::Api::GuestCards.new.getGuestCards(propertycode)
      end

      def get_property_code(params)
        return params[:property_code]
      end

    end
  end
end
