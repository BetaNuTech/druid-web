class EngagementPolicyScheduler
  class Error < StandardError; end

  # Create ScheduledActions and Compliance records
  # for a provided Lead
  def create_scheduled_actions(lead:)
    unless lead.is_a?(Lead)
      msg = "Must Provide a Lead"
      log_error(msg, {lead: lead})
      return false
    end

    property = lead.property
    state = lead.state
    agent = lead.user || lead.property&.primary_agent

    policy = EngagementPolicy.
      latest_version.
      for_property(lead.property_id).
      for_state(lead.state).
      first

    unless policy.present?
      msg = "No EngagementPolicy found for Lead[#{ lead.try(:id) }] with state #{lead.state} assigned to Property #{property.try(:name)}"
      log_error(msg, {lead: lead})
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

    description = "%s [%s]" % [originator.description, 'FOLLOW UP']
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
    incomplete_states = [:pending]
    lead.transaction do
      lead.scheduled_actions.where(state: incomplete_states).each do |action|
        action.user = agent
        action.save
        if (compliance = action.engagement_policy_action_compliance).present?
          compliance.user = agent
          compliance.save
        end
      end
    end
    return true
  end

  def handle_scheduled_action_completion(scheduled_action, user: nil)
    unless (compliance = scheduled_action.engagement_policy_action_compliance).present?
      # Removed because error notifications were excessive
      #log_error("Skipping Compliance Record handling of Updated ScheduledAction because there is none", {scheduled_action: scheduled_action, user: user})
      return true
    end

    # Set completion user if provided
    if user.present?
      scheduled_action.user_id = compliance.user_id = user.id
    end

    # Update Compliance State
    if scheduled_action.state != compliance.state
      case scheduled_action.state
      when 'completed'
        compliance.complete
      when 'completed_retry'
        compliance.retry
      when 'expired'
        compliance.expire
      when 'rejected'
        compliance.reject
      end

      scheduled_action.add_subject_completion_note
    end

    return true
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

  # Create a new 'orphan' EngagementPolicyAction, EngagementPolicyActionCompliance, ScheduledAction, and Schedule
  #   so that completion will award points
  def create_lead_incoming_message_reply_task(message)
    deadline_hours = 2

    lead = message.messageable
    return nil unless lead.is_a?(Lead)

    lead_action = LeadAction.active.where(name: 'Send Email').first
    if lead_action.nil?
      raise EngagementPolicyScheduler::Error.new("Lead Action 'Send Email' is missing. Can't create message reply task.")
    end

    reason = Reason.where(name: 'Message Response').first
    if reason.nil?
      raise EngagementPolicyScheduler::Error.new("Reason 'Message Response' is missing. Can't create message reply task.")
    end

    due = message.delivered_at.utc + deadline_hours.hours

    action = nil

    ActiveRecord::Base.transaction do

      policy_action = EngagementPolicyAction.new(
        engagement_policy_id: nil,
        lead_action_id: lead_action.id,
        description: 'Require response to incoming message',
        deadline: deadline_hours,
        score: 2.0
      )

      policy_action.save or
        raise EngagementPolicyScheduler::Error.new("Could not create Engagement Policy Action: #{policy_action.errors}")

      schedule = Schedule.new(
        date: due.to_date,
        time: due.to_time,
        rule: 'singular',
        interval: 1
      )

      action = ScheduledAction.new(
        target: lead,
        originator_id: nil,
        lead_action: lead_action,
        reason: reason,
        schedule: schedule,
        engagement_policy_action: policy_action,
        description: "Respond to incoming Message from #{lead.name}"
      )

      action.save or
        raise EngagementPolicyScheduler::Error.new("Could not create Scheduled Action: #{policy_action.errors}")

      compliance = EngagementPolicyActionCompliance.new(
        scheduled_action: action,
        expires_at: due
      )

      action.engagement_policy_action_compliance = compliance
      action.save or
        raise EngagementPolicyScheduler::Error.new("Could not create Scheduled Action: #{policy_action.errors}")

      action.reload
    end

    return action

  rescue EngagementPolicyScheduler::Error => e
    error_data = {
      property: lead.property&.name,
      lead: lead.id,
      lead_name: lead.name,
      message: message.id
    }
    ErrorNotification.send(e, error_data)
    return nil
  end

  private

  def default_reason
    reason = Reason.active.where(name: 'Scheduled').first
    return reason
  end

  def log_error(msg, notification=true)
    message = "EngagementPolicyScheduler ERROR: " + msg
    Rails.logger.error message
    ErrorNotification.send(Error.new(message))
  end

end
