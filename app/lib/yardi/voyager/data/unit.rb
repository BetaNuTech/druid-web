module Yardi
  module Voyager
    module Data
      class Unit
        require 'nokogiri'

        attr_accessor :remoteid, :name, :unit_type, :bedrooms, :bathrooms, :sqft, :occupancy, :lease_status, :available_on, :market_rent, :floorplan_name, :floorplan_id

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
            error_messages = data['Envelope']['Body']["#{method}Response"]["#{method}Result"].fetch('Messages',false)
            if error_messages
              err_msg = error_messages['Message'].fetch('__content__', 'Unknown error')
              raise Yardi::Voyager::Data::Error.new(err_msg)
            end

            # Extract Unit Data
            root_node = data['Envelope']['Body']["#{method}Response"]["#{method}Result"]['PhysicalProperty']['Property']['ILS_Unit']

          rescue => e
            raise Yardi::Voyager::Data::Error.new("Invalid Unit data schema: #{e}")
          end

          raw_units = root_node.map{|record| Unit.from_unit_node(record)}.flatten

          return raw_units
        end

        def self.from_unit_node(data)
          # TODO
          return nil
        end

      end
    end
  end
end
