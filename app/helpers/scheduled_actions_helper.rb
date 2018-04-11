module ScheduledActionsHelper

  def select_scheduled_action_action(action)
    #options = [ ['Add Note', 'note'], ['Mark Complete', 'complete'], ['Mark Complete and Retry Later', 'complete_retry'] ]
    options = [ ['Mark Complete', 'complete'], ['Mark Complete and Retry Later', 'complete_retry'] ]
    options_for_select(options, action)
  end
end
