module Notes
  module Leads
    extend ActiveSupport::Concern

    included do

      after_create :lead_action_contact_check

      def lead_action_contact_check
        return true unless notable.present? && notable.is_a?(Lead)
        lead = notable
        if lead_action.present? && lead_action.is_contact
          lead.last_comm = DateTime.now
          lead.save
        end
        return true
      end

    end
  end
end
