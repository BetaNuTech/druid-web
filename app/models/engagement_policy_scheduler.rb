class EngagementPolicyScheduler
  class Error < StandardError; end

  # Create ScheduledActions and Compliance records
  # for a provided Lead
  def create_scheduled_actions(lead:)
    unless lead.is_a?(Lead)
      msg = "Must Provide a Lead"
      log_error(msg)
      return []
    end

    property = lead.property
    state = lead.state
    agent = lead.user || lead.property.try(:primary_agent)

    policy = EngagementPolicy.
      latest_version.
      for_property(lead.property_id).
      for_state(lead.state).
      first

    unless policy.present?
      msg = "No EngagementPolicy found for Lead[#{ lead.try(:id) }] with state #{lead.state} assigned to Property #{property.try(:name)}"
      log_error(msg)
      return []
    end

    actions = []
    ActiveRecord::Base.transaction do
      actions = policy.actions.active.map do |policy_action|

        old_action = ScheduledAction.where(
          target: lead,
          engagement_policy_action: policy_action
        ).first

        if old_action.present?
          msg = "EngagementPolicyScheduler WARNING: ScheduledAction for Lead[#{lead.id}] and EngagementPolicyAction[#{policy_action.description}] already present"
          puts msg
          Rails.logger.warn msg
          next
        end

        due = DateTime.now.utc + policy_action.deadline.hours
        schedule = Schedule.new(
          date: due.to_date,
          time: due.to_time,
          # Single instance schedule
          rule: "singular",
          interval: 1
        )

        action = ScheduledAction.new(
          user: agent,
          target: lead,
          originator_id: nil,
          lead_action: policy_action.lead_action,
          reason: default_reason,
          schedule: schedule,
          engagement_policy_action: policy_action,
          description: policy_action.lead_action.description
        )
        action.save!

        compliance = EngagementPolicyActionCompliance.new(
          scheduled_action: action,
          user: agent,
          expires_at: due
        )

        action.engagement_policy_action_compliance = compliance
        action.save!
        action.reload

        action
      end
    end

    # Remove any nil values from Array which would be present if
    # the ScheduledAction for this Lead and EngagementPolicyAction already exists.
    actions = actions.compact

    return actions
  end

  # Returns boolean indicating if all state ScheduledActions for
  # a Lead are complete
  def can_lead_progress?(lead:)
    return false
  end

  # Re-assign incomplete ScheduledActions
  def reassign_lead(lead:, agent:)
    return false
  end

  private

  def default_reason
    reason = Reason.active.where(name: 'Scheduled').first
    return reason
  end

  def log_error(msg)
    message = "EngagementPolicyScheduler ERROR: " + msg
    Rails.logger.error message
  end

end
