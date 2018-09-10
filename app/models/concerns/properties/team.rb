module Properties
  module Team
    extend ActiveSupport::Concern

    included do
      belongs_to :team, optional: true

      delegate :agents, to: :team, allow_nil: true
      delegate :teamleads, to: :team, allow_nil: true
      delegate :managers, to: :team, allow_nil: true

      def primary_agent
        ( teamleads || managers || agents ).try(:first)
      end

    end
  end
end
