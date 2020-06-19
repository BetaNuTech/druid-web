module RoommatesHelper
  def roommate_occupancies_for_select(occupancy)
    options_for_select(Roommate.occupancies.keys.map{|k| [k.capitalize, k]}, occupancy)
  end

  def roommate_relationships_for_select(relationship)
    options_for_select(Roommate.relationships.keys.map{|k| [k.capitalize, k]}, relationship)
  end
end
