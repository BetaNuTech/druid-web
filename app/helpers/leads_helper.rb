module LeadsHelper
  def titles_for_select
    options_for_select %w{Ms. Mrs. Mr. Mx. Dr.}
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
end
