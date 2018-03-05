module ResidentsHelper
  def select_resident_status(val)
    options_for_select(Resident::STATUS_OPTIONS.map{|o| [o.capitalize, o]}, val)
  end
end
