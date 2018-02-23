module UnitTypesHelper

  def select_property(val)
    options_for_select(Property.order(name: 'ASC').map{|p| [p.name, p.id]}, val)
  end
end
