module Leads
  module EngagementPolicy
    extend ActiveSupport::Concern

    included do
      after_create :create_scheduled_actions
      after_save :ensure_scheduled_action_ownership

      def create_scheduled_actions
        EngagementPolicyScheduler.new.create_scheduled_actions(lead: self)
      end

      def reassign_scheduled_actions
        EngagementPolicyScheduler.new.reassign_lead_agent(lead: self, agent: self.user)
      end

      def ensure_scheduled_action_ownership
        if self.saved_change_to_attribute?(:user_id)
          reassign_scheduled_actions
        end
      end

      def send_application_to_lead
        LeadMailer.with(lead: self).application_link.deliver_later
      end
    end
  end
end
