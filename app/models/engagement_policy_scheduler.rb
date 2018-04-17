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
          puts msg unless Rails.production?
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
    if originator.personal_task?
      msg = "EngagementPolicyScheduler: cannot retry Personal Task ScheduledAction[#{originator.id}]"
      puts msg unless Rails.production?
      Rails.logger.warn msg
      return nil
    end

    attempt = ( originator.attempt || 1 ) + 1
    max_attempts = originator.engagement_policy_action.retry_count || 0

    # Abort and return if we have reached max attempts
    if attempt > max_attempts
      msg = "EngagementPolicyScheduler: Reached max attempts #{max_attempts} for ScheduledAction[#{originator.id}]"
      puts msg unless Rails.production?
      Rails.logger.warn msg
      return nil
    end

    due = originator.engagement_policy_action.next_scheduled_attempt

    schedule = Schedule.new(
      date: due.to_date,
      time: due.to_time,
      # Single instance schedule
      rule: "singular",
      interval: 1
    )

    description = "[ATTEMPT #{attempt}/#{max_attemps}] " + originator.lead_action.description
    action = ScheduledAction.new(
      user: originator.user,
      target: originator.lead,
      originator: originator,
      lead_action: originator.lead_action,
      reason: default_reason,
      schedule: schedule,
      engagement_policy_action: originator.engagement_policy_action,
      description: description,
      attempt: ( originator.attempt || 1 ) + 1
    )
    action.save!

    compliance = EngagementPolicyActionCompliance.new(
      scheduled_action: action,
      user: originator.user,
      expires_at: due
    )

    action.engagement_policy_action_compliance = compliance
    action.save!
    action.reload

    action

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
    compliance = scheduled_action.engagement_policy_action_compliance
    compliance.state = 'pending'
    compliance.score = nil
    compliance.memo = nil
    compliance.completed_at = nil
    compliance.save!
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
