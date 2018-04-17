module ScheduledActionsHelper

  def select_scheduled_action_action(scheduled_action)
    action = scheduled_action.completion_action

    option_labels = {
      complete: 'Mark Complete',
      retry: 'Mark Complete and Retry Later',
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
end
