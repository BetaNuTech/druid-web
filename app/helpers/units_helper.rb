module UnitsHelper
  def select_unit(property: nil, val:)
    skope = Unit
    if property.present? && property.is_a?(Property)
      skope = property.housing_units
    end
    options_for_select(skope.order(unit: 'ASC').map{|p| [p.unit, p.id]}, val)
  end
end
