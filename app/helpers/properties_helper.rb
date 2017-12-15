module PropertiesHelper
  def property_address_block(property)
    content_tag(:span, class: "property-address-block") do
      content_tag(:span, class: 'property-address-block-address') do
        [sanitize( property.address1 ), sanitize( property.address2 ), sanitize(property.address3)].reject(&:empty?).join('<br/>').html_safe
      end +
      content_tag(:span, class: 'property-address-block-csz') do
        ( '<br/>' +
        "%s, %s %s" % [sanitize(property.city), sanitize(property.state), sanitize(property.zip)] ).html_safe
      end +
      content_tag(:span, class: 'property-address-block-country') do
        unless property.country.empty?
          ( '<br/>' + sanitize(property.country) ).html_safe
        end
      end
    end
  end

  def property_active_table_row_class(property)
    return property.active ? 'property-table-row-active' : 'property-table-row-inactive'
  end
end
