module Notes
  module Leads
    extend ActiveSupport::Concern

    included do
      after_create :update_lead_last_comm_from_lead_action_note
    end

    def update_lead_last_comm_from_lead_action_note
      return true unless self.notable.is_a?(LeadAction) && self.notable.is_contact?

      # Find the lead through ScheduledAction that connects the LeadAction to a Lead
      associated_lead = if self.notable.respond_to?(:lead)
        # Direct access if available
        self.notable.lead
      else
        # Find through ScheduledAction
        scheduled_action = ScheduledAction.where(lead_action_id: self.notable.id, target_type: 'Lead').first
        scheduled_action&.target
      end
      
      return true unless associated_lead.is_a?(Lead)

      associated_lead.make_contact(
        article: self,
        timestamp: self.created_at,
        description: "Action: #{self.notable.name}"
      )
      true
    end

  end
end
