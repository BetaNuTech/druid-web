module Properties
  module YardiVoyager
    extend ActiveSupport::Concern

    class_methods do
      def with_yardi_code(code)
        Leads::Adapters::YardiVoyager.property(code)
      end
    end

    included do

      def new_leads_for_sync
        # Include leads in early pipeline with assigned user
        # AND leads in 'future' state without remoteid (even if user_id is nil,
        # since nurture event clears user_id but we can find last assigned user from transitions)
        return leads.
          where(remoteid: [ nil, '' ]).
          where(
            "(state IN (?) AND user_id IS NOT NULL) OR state = ?",
            Lead::EARLY_PIPELINE_STATES,
            'future'
          )
      end

      def leads_for_sync
        return leads.
          where(state: Lead::IN_PROGRESS_STATES).
          where.not(remoteid: [nil, '']).
          where.not(user_id: nil)
      end

      def leads_for_cancelling
        return leads.
          where(state: ['invalidated']).
          where.not(remoteid: [nil, ''])
          # Note: invalidated leads retain their user_id, so no user_id constraint needed
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

      def voyager_guestcards(start_date: nil, end_date: DateTime.current, filter: false)
        adapter = Leads::Adapters::YardiVoyager.new(self)
        return adapter.fetch_GuestCards(start_date: start_date, end_date: end_date, filter: filter)
      end

    end
  end
end
