module PropertiesHelper
  def property_address_block(property)
    content_tag(:span, class: "property-address-block") do
      content_tag(:span, class: 'property-address-block-address') do
        [sanitize( property.address1 ), sanitize( property.address2 ), sanitize(property.address3)].compact.reject(&:empty?).join('<br/>').html_safe
      end +
      content_tag(:span, class: 'property-address-block-csz') do
        ( '<br/>' +
        "%s, %s %s" % [sanitize(property.city), sanitize(property.state), sanitize(property.zip)] ).html_safe
      end +
      content_tag(:span, class: 'property-address-block-country') do
        if property.country.present?
          ( '<br/>' + sanitize(property.country) ).html_safe
        end
      end
    end
  end

  def property_active_table_row_class(property)
    return property.active ? 'property-table-row-active' : 'property-table-row-inactive'
  end

  def select_property(val)
    options_for_select(Property.order(name: 'ASC').map{|p| [p.name, p.id]}, val)
  end

  def select_property_user(property:, selected:, all: false)
    if all
      available_users = User.includes(:profile).where.not(id: property.users.select(:id).map(&:id))
    else
      available_users = property.users_available_for_assignment
    end

    selected_user = selected.present? ? [ User.find(selected) ] : []
    select_users = (selected_user + available_users).sort_by{|u| u.profile&.last_name + u.profile&.first_name}

    user_options = select_users.map{|u|
      property_list = ['none']
      if u.properties.any?
        property_list = u.properties.map{|p| p.name}
      end
      property_list = property_list.join(',')

      [ ( "%s (%s)" % [ u.name, property_list] ), u.id ]
    }

    options_for_select(user_options, selected)
  end

  def select_user_role(selected)
    options_for_select(PropertyUser.roles.to_a.map{|r| [r[0].capitalize, r[0]]}, selected)
  end

  def property_options_for_current(val)
    options_for_select(PropertyPolicy.new(current_user,Property).for_lead_assignment.order(name: 'ASC').map{|p| [p.name, p.id]}, val)
  end

  def morning_hours_options(val)
    option_arr = []
    ( 5..11 ).each do |hour|
      opt = "#{hour}:00 AM"
      option_arr << [opt, opt]
      opt = "#{hour}:30 AM"
      option_arr << [opt, opt]
    end
    option_arr << ["12:00 PM", "12:00 PM"]
    option_arr << ["12:30 PM", "12:30 PM"]
    options_for_select(option_arr, val)
  end

  def afternoon_hours_options(val)
    option_arr = []
    option_arr << ["12:00 PM", "12:00 PM"]
    option_arr << ["12:30 PM", "12:30 PM"]
    ( 1..11 ).each do |hour|
      opt = "#{hour}:00 PM"
      option_arr << [opt, opt]
      opt = "#{hour}:30 PM"
      option_arr << [opt, opt]
    end
    options_for_select(option_arr, val)
  end
end
