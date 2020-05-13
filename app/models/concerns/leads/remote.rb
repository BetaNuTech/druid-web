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
        return false unless remoteid.present?

        unless (guestcard = voyager_guestcard(debug))
          # Handle unexpected missing guestcard
          data_sync_reason = Reason.where(name: 'Data Sync').last
          data_sync_action = LeadAction.where(name: 'Sync from Remote').last
          Note.create( # create_event_note
            classification: 'error',
            notable: self,
            content: 'Attempted a manual Guestcard to Lead Update but Voyager did not return a GuestCard as expected!',
            reason: data_sync_reason,
            lead_action: data_sync_action
          )
          return false
        end

        adapter = Leads::Adapters::YardiVoyager.new(property)
        adapter.send(:lead_from_guestcard, guestcard)
        reload
        return self
      end

    end


  end
end
