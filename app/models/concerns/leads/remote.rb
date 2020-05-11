module Leads
  module Remote
    extend ActiveSupport::Concern

    included do

      def remote_record
        case source&.slug
        when 'yardivoyager'
          return voyager_guestcard
        else
          return nil
        end
      end


      def update_from_remote!
        case source&.slug
        when 'YardiVoyager'
          return update_lead_from_voyager_guestcard
        else
          return nil
        end
      end

      def can_update_from_remote?
        return source.present? && remoteid.present?
      end

      def voyager_guestcard(debug=false)
        adapter = Leads::Adapters::YardiVoyager.new(property)
        return adapter.findLeadGuestCard(self, debug: debug)
      end

      def update_lead_from_voyager_guestcard(debug=false)
        guestcard = voyager_guestcard(debug)
        adapter = Leads::Adapters::YardiVoyager.new(property)
        adapter.send(:lead_from_guestcard, guestcard)
        reload

        return self
      end

    end


  end
end
