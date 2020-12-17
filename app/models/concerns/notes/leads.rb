module Notes
  module Leads
    extend ActiveSupport::Concern

    included do

      after_create :lead_action_contact_check

      def lead_action_contact_check
        return true unless notable.present? && notable.is_a?(Lead) && lead_action.present? && lead_action.is_contact

        notable.make_contact(timestamp: Time.now, description: 'Agent made note of a Lead contact')
      end

    end
  end
end
