module Properties
  module YardiVoyager
    extend ActiveSupport::Concern

    included do

      def new_leads_for_sync
        return leads.
          where(remoteid: [ nil, '' ], state: Lead::EARLY_PIPELINE_STATES).
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
          where(state: [ 'disqualified', 'abandoned' ]).
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

      def voyager_guestcards(start_date: nil, end_date: DateTime.now, filter: false)
        adapter = Leads::Adapters::YardiVoyager.new(self)
        return adapter.fetch_GuestCards(start_date: start_date, end_date: end_date, filter: filter)
      end

    end
  end
end
