module Leads
  module Remote
    extend ActiveSupport::Concern

    included do

      def remote_record
        return voyager_guestcard
      end

      def update_from_remote!
        return update_lead_from_voyager_guestcard
      end

      def can_update_from_remote?
        return remoteid.present?
      end

      def voyager_guestcard(debug=false)
        return nil unless remoteid.present?
        adapter = Leads::Adapters::YardiVoyager.new(property)
        return adapter.findLeadGuestCard(self, debug: debug)
      end

      def update_lead_from_voyager_guestcard(debug=false)
        return nil unless remoteid.present?
        guestcard = voyager_guestcard(debug)
        adapter = Leads::Adapters::YardiVoyager.new(property)
        adapter.send(:lead_from_guestcard, guestcard)
        reload
        return self
      end

    end


  end
end
