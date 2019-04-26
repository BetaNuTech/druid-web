module LeadsHelper

  def unit_types_for_select(property:, value:)
    return [] unless property.present?
    options_from_collection_for_select(property.unit_types.active.order('name asc'), 'id', 'name', value)
  end

  def titles_for_select(val)
    options_for_select(%w{Ms. Mrs. Mr. Mx. Dr.}, val)
  end

  def display_preference_option(pref_attr)
    case pref_attr
    when Date,DateTime,ActiveSupport::TimeWithZone
      short_date(pref_attr)
    when String,Numeric
      pref_attr
    else
      pref_attr.present? ? 'Y' : 'No preference'
    end
  end

  def sources_for_select(lead_source_id)
    options_from_collection_for_select(LeadSource.active.order('name asc'), 'id', 'name', lead_source_id)
  end

  def properties_for_select(property_id)
    options_from_collection_for_select(Property.active.order('name asc'), 'id', 'name', property_id)
  end

  def state_toggle(lead)
    render partial: "leads/state_toggle", locals: { lead: lead }
  end

  def trigger_lead_state_event(lead:, event_name:)
    success = false
    if policy(lead).allow_state_event_by_user?(event_name)
      success = lead.trigger_event(event_name: event_name, user: current_user)
    end
    return success
  end

  def users_for_select(lead)
    options_from_collection_for_select(
      lead.users_for_lead_assignment(default: current_user),
      'id', 'name', lead.user_id
    )
  end

  def priorities_for_select(lead)
    options_for_select(Lead.priorities.to_a.map{|p| [p[0].capitalize, p[0]]}, lead.priority)
  end

  def lead_priority_icon(lead)
    return "(?)" unless lead.present? && lead.priority.present?

    priority = lead.priority.to_sym
    icon_settings = {
      zero: {icon_count: 1, color: 'gray'},
      low: {icon_count: 2, color: 'black'},
      medium: {icon_count: 3, color: 'yellow'},
      high: {icon_count: 4, color: 'orange'},
      urgent: {icon_count: 5, color: 'red'}
    }

    container_class = "lead_priority_icon_#{priority}"
    color = icon_settings[priority][:color]
    count = icon_settings[priority][:icon_count]

    return tag.span(class: container_class, style: "opacity: 1 !important; color: '#{color}'") do
      count.times do
        concat(glyph(:fire))
      end
    end
  end

  def lead_state_label(lead)
    tag.span(class: 'label label-success') do
      lead.state.try(:titlecase)
    end
  end

  def call_log_timestamp(lead)
    please_wait_message =  ' (Pending update: please wait)'
    if lead.call_log_updated_at.nil?
      last_updated_message = please_wait_message
    else
      last_updated_message = 'Last updated ' + distance_of_time_in_words(lead.call_log_updated_at || DateTime.now, DateTime.now) + ' ago.'
      if lead.should_update_call_log?
        last_updated_message += please_wait_message
      end
    end
    return last_updated_message
  end

  def select_lead_comment_action(lead, val=nil)
    all_actions = LeadAction.order(name: 'ASC').to_a.map{|a| [a.name, a.id]}
    next_actions = lead.scheduled_actions.pending.
      includes(:engagement_policy_action_compliance).
      order("engagement_policy_action_compliances.expires_at ASC").
      map(&:lead_action).to_a.map{|a| [a.name, a.id]}
    options = {
      'Pending Tasks' => next_actions,
      'All' => all_actions - next_actions
    }
    val ||= next_actions.first
    grouped_options_for_select(options, val)
  end

  def select_lead_referral_source(val)
    options = LeadReferralSource.order(name: :asc).map do |referral|
      [ referral.name, referral.name ]
    end
    options = ['None', 'None'] + options
    options_for_select(options, val)
  end

end
