module Properties
  module YardiVoyager
    extend ActiveSupport::Concern

    included do

      def new_leads_for_sync
        return leads.
          where(remoteid: [ nil, '' ], state: 'prospect').
          where.not(user_id: nil)
      end

      def leads_for_sync
        return leads.
          where(state: Lead::IN_PROGRESS_STATES).
          where.not(remoteid: [nil, '']).
          where.not(user_id: nil)
      end

      def leads_for_cancelling
        return leads.
          where(state: 'disqualified').
          where.not(remoteid: [nil, '']).
          where.not(user_id: nil)
      end

      def voyager_property_code
        return Leads::Adapters::YardiVoyager.property_code(self)
      end

      def updateVoyagerGuestCards
        adapter = Leads::Adapters::YardiVoyager.new(self)
        adapter.createGuestCards
        adapter.updateGuestCards
        adapter.cancelGuestCards
      end

    end
  end
end
