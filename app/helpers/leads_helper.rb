module LeadsHelper
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
    options_from_collection_for_select(User.all, 'id', 'name', lead.user_id)
  end

  def priorities_for_select(lead)
    options_for_select(Lead.priorities.to_a.map{|p| [p[0].capitalize, p[0]]}, lead.priority)
  end
end
