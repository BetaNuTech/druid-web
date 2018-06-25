module UnitsHelper
  def select_unit(property: nil, val:)
    skope = Unit
    if property.present? && property.is_a?(Property)
      skope = property.housing_units
    end
    options_for_select(skope.order(unit: 'ASC').map{|p| [p.unit, p.id]}, val)
  end

  def select_occupancy(val)
    options_for_select(Unit::OCCUPANCY_STATUSES.map{|s| [s.capitalize, s]}, val)
  end

  def select_lease_status(val)
    options_for_select(Unit::LEASE_STATUSES.map{|s| [s.humanize.capitalize, s]}, val)
  end
end
