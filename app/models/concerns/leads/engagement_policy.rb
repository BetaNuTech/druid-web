module Leads
  module EngagementPolicy
    extend ActiveSupport::Concern

    included do
      after_create :create_scheduled_actions

      def create_scheduled_actions
        EngagementPolicyScheduler.new.create_scheduled_actions(lead: self)
      end
    end
  end
end
