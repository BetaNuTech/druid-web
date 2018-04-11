module ScheduledActionsHelper

  def select_scheduled_action_action(action)
    #options = [ ['Add Note', 'note'], ['Mark Complete', 'complete'], ['Mark Complete and Retry Later', 'complete_retry'] ]
    options = [ ['Mark Complete', 'complete'], ['Mark Complete and Retry Later', 'complete_retry'], ['Reject', 'reject'] ]
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
    else
      action.state
    end
  end
end
