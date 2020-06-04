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

  def scheduled_action_schedule_durations(schedule=nil)
    options = [ ["Free", 0], ["30 minutes",30], ["60 minutes",60], ["90 minutes",90], ["120 minutes", 120] ]
    return options_for_select(options, ( schedule.try(:duration) || 0 ))
  end

  def scheduled_action_article_select(scheduled_action:, action: nil)
    config = scheduled_action.article_select_config(action: action)
    return '' unless config
    content_tag(:div, id: 'scheduled_action_article_select') do
      concat hidden_field_tag('scheduled_action[article_type]', config[:class])

      if config[:options_grouped]
        select_options = scheduled_action_article_grouped_select_options( scheduled_action: scheduled_action, action: action)
      else
        select_options = scheduled_action_article_select_options( scheduled_action: scheduled_action, action: action)
      end
      concat select_tag('scheduled_action[article_id]',
                 select_options,
                 class: 'form-control selectize-nocreate',
                 prompt: config[:prompt])
    end
  end

  def scheduled_action_article_select_options(scheduled_action:, action:)
    config = scheduled_action.article_select_config(action: action)
    collection = config[:options].call( current_user: current_user, target: scheduled_action.target)
    options_from_collection_for_select(collection, 'id', config[:record_descriptor], scheduled_action.article&.id)
  end

  def scheduled_action_article_grouped_select_options(scheduled_action:, action:)
    config = scheduled_action.article_select_config(action: action)
    collection = config[:options].call( current_user: current_user, target: scheduled_action.target, grouped: true)
    collection_for_select = collection.keys.inject({}) do |memo, key|
      memo[key] = collection[key].map{|a| [a.send(config[:record_descriptor]), a.id] }
      memo
    end
    grouped_options_for_select(collection_for_select, scheduled_action.article&.id)
  end

  def scheduled_action_calendar_entry_class(scheduled_action)
    css_classes = [ "scheduled_action_calendar_entry" ]
    css_classes << "scheduled_action_calendar_entry_my_task" if scheduled_action.user_id == current_user.id
    css_classes << 'scheduled_action_calendar_entry_completed' if scheduled_action.is_completed?

    return css_classes.join(" ")
  end

  def scheduled_action_completion_state_icon(scheduled_action)
    case scheduled_action.state
    when 'pending'
      glyph(:flag)
    when 'completed'
      glyph(:ok)
    when 'completed_retry'
      glyph(:duplicate)
    when 'expired'
      glyph(:time)
    when 'rejected'
      glyph(:ban_circle)
    end
  end

  def scheduled_action_user_id_select_options(scheduled_action, current_user)
    if scheduled_action.target&.property&.present?
      collection = scheduled_action.target.property.users.by_name_asc
    else
      collection = [current_user]
    end
   return options_from_collection_for_select(collection, 'id', :name, scheduled_action.user_id || current_user.id)
  end

end
