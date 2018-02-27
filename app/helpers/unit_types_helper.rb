module UnitTypesHelper
  def select_unit_type(val)
    options_for_select(UnitType.order(name: 'ASC').map{|p| [p.name, p.id]}, val)
  end
end
