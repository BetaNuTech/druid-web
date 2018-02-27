module RentalTypesHelper
  def select_rental_type(val)
    options_for_select(RentalType.order(name: 'DESC').map{|p| [p.name, p.id]}, val)
  end
end
