module ScheduledActionsHelper

  def select_scheduled_action_action(scheduled_action)
    action = scheduled_action.completion_action

    option_labels = {
      complete: 'Mark Complete',
      retry: 'Mark Complete and Follow Up Later',
      reject: 'Reject (task is not necessary)',
      expire: 'Expire (too late to complete)'
    }
    permissible_events = scheduled_action.selectable_state_events
    options = permissible_events.map{|e| [option_labels[e.to_sym], e.to_s]}.compact
    options_for_select(options, action)
  end

  def scheduled_action_status(action)
    return case action.state
    when 'pending',
      if action.schedule.to_datetime < DateTime.now
        glyph(:fire)
      else
        glyph(:ok)
      end
    when 'completed'
      if action.schedule.to_datetime < DateTime.now
        glyph(:time)
      else
        glyph(:ok)
      end
    when 'completed_retry'
      glyph(:refresh)
    when 'rejected'
      glyph(:remove)
    when 'expired'
      glyph(:time)
    else
      action.state
    end
  end

  def scheduled_action_completion_retry_delay_select_value(scheduled_action)
    options = ( 1..60 ).to_a.map{|hour| [hour.to_i, hour.to_i]}
    provided_delay = scheduled_action.completion_retry_delay_value.try(:to_i) || 0
    retry_delay = provided_delay == 0 ? ( scheduled_action.engagement_policy_action.try(:retry_delay) || 1 ) : provided_delay

    return options_for_select(options, retry_delay.to_i)
  end

  def scheduled_action_completion_retry_delay_select_unit(scheduled_action)
    options = [['Hours', 'hours'], ['Days','days']]

    provided_delay_unit = scheduled_action.completion_retry_delay_unit
    retry_delay_unit = nil

    if ['hours', 'days'].include?(provided_delay_unit)
      retry_delay_unit = provided_delay_unit
    else
      compliance_delay = ( scheduled_action.engagement_policy_action.try(:retry_delay) || 1).to_f / 24.0 # in days
      compliance_delay_unit = (compliance_delay >= 1.0) ? 'days' : 'hours'
      retry_delay_unit = compliance_delay_unit
    end

    return options_for_select(options, retry_delay_unit)
  end


  def trigger_scheduled_action_state_event(scheduled_action:, event_name:, user: current_user)
    success = false
    if policy(scheduled_action).allow_state_event_by_user?(event_name)
      success = scheduled_action.trigger_event(event_name: event_name, user: user)
    end
    return success
  end

end
