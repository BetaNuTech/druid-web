module Yardi
  module Voyager
    class Prospect
      attr_reader :first_name, :last_name, 
                  :prospect_id, :third_party_id,
                  :property_id,
                  :address1, :address2, :city, :state, :postalcode,
                  :email,
                  :phones,
                  :expected_move_in, :lease_from, :lease_to,
                  :move_in, :floorplan, :unit, :rent, :bedrooms,
                  :preference_comment,
                  :events
    end
  end
end
