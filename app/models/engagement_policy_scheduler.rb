class EngagementPolicyScheduler
  class Error < StandardError; end

  # Create ScheduledActions and Compliance records
  # for a provided Lead
  def create_scheduled_actions(lead:)
    unless lead.is_a?(Lead)
      msg = "Must Provide a Lead"
      log_error(msg)
      return false
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
      return true
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
          puts msg unless Rails.env.production?
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

  def create_retry_record(originator)
    attempt = ( originator.attempt || 1 ) + 1
    max_attempts = originator.max_attempts || 1

    # Abort and return if we have reached max attempts
    if originator.final_attempt?
      msg = "EngagementPolicyScheduler: Reached max attempts #{max_attempts} for ScheduledAction[#{originator.id}]"
      Rails.logger.warn msg
      return nil
    end

    due = originator.next_scheduled_attempt(attempt)

    schedule = Schedule.new(
      date: due.to_date,
      time: due.to_time,
      # Single instance schedule
      rule: "singular",
      interval: 1
    )

    description = "%s [%s]" % [originator.description, 'RETRY']
    action = ScheduledAction.new(
      user: originator.user,
      target: originator.target,
      originator: originator,
      lead_action: originator.lead_action,
      reason: default_reason,
      schedule: schedule,
      engagement_policy_action: originator.engagement_policy_action,
      description: description,
      attempt: ( originator.attempt || 1 ) + 1
    )
    action.save!

    if originator.compliance_task?
      compliance = EngagementPolicyActionCompliance.new(
        scheduled_action: action,
        user: originator.user,
        expires_at: due
      )

      action.engagement_policy_action_compliance = compliance
      action.save!
    end
    action.reload

    return action
  end

  # Re-assign incomplete ScheduledActions
  def reassign_lead_agent(lead:, agent:)
    incomplete_states = [:pending, :expired]
    lead.transaction do
      lead.scheduled_actions.where(state: incomplete_states).each do |action|
        action.user = agent
        action.save
        compliance = action.engagement_policy_action_compliance
        compliance.user = agent
        compliance.save
      end
    end
    return true
  end

  def handle_scheduled_action_completion(scheduled_action)
    unless (compliance = scheduled_action.engagement_policy_action_compliance).present?
      log_error("Skipping Compliance Record handling of Updated ScheduledAction because there is none")
      return true
    end

    scheduled_action.add_subject_completion_note

    case scheduled_action.state
    when 'completed'
      compliance.complete!
    when 'completed_retry'
      compliance.retry!
    when 'expired'
      compliance.expire!
    when 'rejected'
      compliance.reject!
    end
  end

  def reset_completion_status(scheduled_action)
    scheduled_action.state = 'pending'
    scheduled_action.completed_at = nil
    scheduled_action.save!
    if scheduled_action.engagement_policy_action_compliance.present?
      compliance = scheduled_action.engagement_policy_action_compliance
      compliance.state = 'pending'
      compliance.score = nil
      compliance.memo = nil
      compliance.completed_at = nil
      compliance.save!
    end
  end

  private

  def default_reason
    reason = Reason.active.where(name: 'Scheduled').first
    return reason
  end

  def log_error(msg)
    message = "EngagementPolicyScheduler ERROR: " + msg
    Rails.logger.error message
    ErrorNotification.send(Error.new(message))
  end

end
