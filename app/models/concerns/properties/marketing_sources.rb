module Properties
  module MarketingSources
    extend ActiveSupport::Concern

    included do
      has_many :marketing_sources

      # Given an incoming number, return the matching MarketingSource name
      def referral_name_for_incoming_number(number)
        marketing_sources.where(tracking_number: number).first&.name
      end
    end
  end
end
