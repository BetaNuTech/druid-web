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
end
