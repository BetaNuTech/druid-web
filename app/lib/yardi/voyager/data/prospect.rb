module Yardi
  module Voyager
    module Data
      class Prospect
        require 'nokogiri'

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

        def self.parse_xml(xml_string)

          prospects = []
          dom = Nokogiri::XML(xml_string)
          dom.css("Prospect").each do |prospect_node|
            prospect = {}
            prospect_node.css("Identification").each do |identification_node|
              binding.pry
              idtype = identification_node.attributes["IDType"]
              case idtype
              when "ThirdPartyID"
                identification_node[:third_party_id] = identification_node["IDValue"]
              when "ProspectID"
                identification_node[:prospect_id] = identification_node["IDValue"]
              when "PropertyID"
                identification_node[:property_id] = identification_node["IDValue"]
              end
            end
          end

          puts prospects.inspect

        end

      end
    end
  end
end
