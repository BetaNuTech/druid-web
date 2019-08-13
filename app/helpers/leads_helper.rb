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
      map(&:lead_action).compact.to_a.map{|a| [a.name, a.id]}
    options = {
      'Pending Tasks' => next_actions,
      'All' => all_actions - next_actions
    }
    val ||= next_actions.first
    grouped_options_for_select(options, val)
  end

  def select_lead_referral_source(val)
    default_options = LeadReferralSource.order(name: :asc).pluck(:name)
    current_option = val.present? ? [val] : ['None']
    options = (current_option + default_options).uniq.map{|o| [o,o]}
    options_for_select(options, val)
  end

  def lead_referrable_select(lead:, referral:)
    lead_referral_source = LeadReferralSource.where(name: referral).first
    recognized_source = lead_referral_source.present?

    if recognized_source
      config = lead.referral_select_config(referral: referral)
      display_selector = config.present?

      referrals = lead.referrals.where(lead_referral_source_id: lead_referral_source.id).to_a
      if referrals.empty?
        referrals << LeadReferral.new(lead_id: lead.id, lead_referral_source_id: lead_referral_source&.id)
      end
    end

    content_tag(:div, id: 'lead_referral_referrable_select') do
      ( referrals || [] ).each_with_index do |lead_referral, index|
        param_base = "lead[referrals_attributes][#{index}]"
        if recognized_source
          concat hidden_field_tag("#{param_base}[lead_referral_source_id]", lead_referral_source.id)

          if display_selector
            if config[:options_grouped]
              select_options = lead_referrable_grouped_select_options(lead: lead, referral: lead_referral)
            else
              select_options = lead_referrable_select_options(lead: lead, referral: lead_referral)
            end

            concat hidden_field_tag("#{param_base}[id]", lead_referral.id) if lead_referral.id.present?
            concat hidden_field_tag("#{param_base}[referrable_type]", config[:referral])
            concat label_tag("Referrer")
            concat select_tag("#{param_base}[referrable_id]",
                              select_options,
                              class: 'form-control selectize-nocreate',
                              prompt: config[:prompt])
            concat text_field_tag("#{param_base}[note]", lead_referral.note, class: "form-control", placeholder: "Notes")
            if lead_referral.id?
              concat check_box_tag("#{param_base}[_destroy]")
              concat label_tag("#{param_base}[_destroy]", "Remove")
            end
          end # display_selector?
        end # recognized_source?
      end # each
    end # content_tag

  end

  def lead_referrable_select_options(lead:, referral:)
    config = lead.referral_select_config(referral: referral)
    collection = config[:options].call(current_user: current_user, property: lead.property, grouped: false)
    options_from_collection_for_select(collection, 'id', config[:record_descriptor], referral.referrable&.id)
  end

  def lead_referrable_grouped_select_options(lead:, referral:)
    config = lead.referral_select_config(referral: referral)
    return [] unless config.present?
    collection = config[:options].call(current_user: current_user, property: lead.property, grouped: true)
    collection_for_select = collection.keys.inject({}) do |memo, key|
      memo[key] = collection[key].map{|a| [a.send(config[:record_descriptor]), a.id] }
      memo
    end
    grouped_options_for_select(collection_for_select, referral.referrable&.id)
  end

end
