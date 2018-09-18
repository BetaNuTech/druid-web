module PhoneNumbersHelper
  def select_phone_number_category(val)
    options_for_select(PhoneNumber.categories.keys.map{|k| [k.humanize,k]},val)
  end
  def select_phone_number_availability(val)
    options_for_select(PhoneNumber.availabilities.keys.map{|k| [k.humanize,k]},val)
  end

end
