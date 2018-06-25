module Yardi
  module Voyager
    module Data
      class Unit
        require 'nokogiri'

        attr_accessor :remoteid, :name, :unit_type, :bedrooms, :bathrooms, :sqft, :occupancy, :lease_status, :available_on, :market_rent, :floorplan_name

        def self.from_yardi_unit
        end

      end
    end
  end
end
