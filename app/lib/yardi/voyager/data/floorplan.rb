module Yardi
  module Voyager
    module Data
      class Floorplan
        require 'nokogiri'

        attr_accessor :remoteid, :name, :description, :bedrooms, :bathrooms, :market_rent

        def self.from_yardi_unit
        end

      end
    end
  end
end
