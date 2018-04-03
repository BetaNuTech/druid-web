module Yardi
  module Voyager
    module Data
      class Prospect
        require 'nokogiri'

        attr_reader :prefix_name, :first_name, :middle_name, :last_name,
          :prospect_id, :third_party_id,
          :property_id,
          :address1, :address2, :city, :state, :postalcode,
          :email,
          :phones,
          :expected_move_in, :lease_from, :lease_to,
          :move_in, :floorplan, :unit, :rent, :bedrooms,
          :preference_comment,
          :events

        def self.from_GetYardiGuestActivity_json(json_data)
          # TODO: Create Lead collection from Yardi Voyager GuestCard JSON
          root_node = JSON(json_data)["Envelope"]["Body"]["GetYardiGuestActivity_LoginResponse"]["GetYardiGuestActivity_LoginResult"]["LeadManagement"]["Prospects"]["Prospect"]
          raw_leads = root_node.map{|record| Prospect.new.from_guestcard(record)}

        end

        def from_guestcard(data)
          # TODO: Create Lead from GuestCard Hash
          prospect_record = data["Customers"]["Customer"]
          prospect_preferences = data["CustomerPreferences"]
          prospect_events = data["Events"]
        end

      end
    end
  end
end
