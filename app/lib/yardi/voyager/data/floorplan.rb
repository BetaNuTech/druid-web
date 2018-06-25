module Yardi
  module Voyager
    module Data
      class Floorplan
        require 'nokogiri'

        attr_accessor :remoteid, :name, :description, :sqft, :bedrooms, :bathrooms, :market_rent

        def self.from_UnitAvailability_Login(data)
          self.from_api_response(response: data, method: 'UnitAvailability_Login')
        end

        def self.from_api_response(response:, method:)
          root_node = nil

          case response
          when String
            begin
              data = JSON(response)
            rescue => e
              raise Yardi::Voyager::Data::Error.new("Invalid UnitAvailability JSON: #{e}")
            end
          when Hash
            data = response
          else
            raise Yardi::Voyager::Data::Error.new("Invalid UnitAvailability data. Should be JSON string or Hash")
          end

          begin
            # Handle Server Error
            if data["Envelope"]["Body"].fetch("Fault", false)
              err_msg = data["Envelope"]["Body"]["Fault"].to_s
              raise Yardi::Voyager::Data::Error.new(err_msg)
            end

            # Handle Other Error
            error_messages = data["Envelope"]["Body"]["#{method}Response"]["#{method}Result"].fetch("Messages",false)
            if error_messages
              err_msg = error_messages["Message"].fetch("__content__", "Unknown error")
              raise Yardi::Voyager::Data::Error.new(err_msg)
            end

            # Extract Floorplan Data
            root_node = data["Envelope"]["Body"]["#{method}Response"]["#{method}Result"]['PhysicalProperty']['Property']['Floorplan']

          rescue => e
            raise Yardi::Voyager::Data::Error.new("Invalid Floorplan data schema: #{e}")
          end

          raw_floorplans = root_node.map{|record| Floorplan.from_floorplan_node(record)}.flatten

          return raw_floorplans
        end

        def self.from_floorplan_node(data)
          floorplans = []
          floorplan_record = data
          floorplan = Floorplan.new
          floorplan.name = floorplan_record["Name"]
          floorplan_record["Room"].each do |room|
            case room['RoomType']
            when 'Bedroom'
              floorplan.bedrooms = room["Count"].to_i
            when 'Bathroom'
              floorplan.bathrooms = room["Count"].to_i
            end
          end
          floorplan.sqft = floorplan_record["SquareFeet"]["Max"].to_i
          floorplan.market_rent = floorplan_record["MarketRent"]["Max"].to_f
          floorplan.remoteid = floorplan_record["IDValue"]
          return floorplan
        end
      end
    end
  end
end
