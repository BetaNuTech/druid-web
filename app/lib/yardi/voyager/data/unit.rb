module Yardi
  module Voyager
    module Data
      class Unit
        require 'nokogiri'

        attr_accessor :remoteid, :name, :unit_type, :bedrooms, :bathrooms, :sqft, :occupancy, :lease_status, :available_on, :market_rent, :floorplan_name, :floorplan_id, :model

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
          unit = Unit.new

          if ( availability = data.fetch('Availability',{}).fetch('MadeReadyDate', nil)).present?
            begin
              availability_date =  Date.new(availability['Year'].to_i, availability['Month'].to_i, availability['Day'].to_i)
            rescue => e
              availability_date = nil
              msg = "Invalid Unit data schema: #{availability.inspect}. Error: #{e}"
              Rails.logger.error msg
              #raise Yardi::Voyager::Data::Error.new(msg)
            end
            unit.available_on = availability_date
          end

          data['Units']['Unit'].tap do |unit_data|
            unit.remoteid = unit_data['Identification']['IDValue']
            unit.name = unit_data['Identification']['IDValue']
            unit.floorplan_id = unit_data['UnitType']
            unit.floorplan_name = unit_data['FloorplanName']
            unit.bedrooms = unit_data['UnitBedrooms'].to_i
            unit.bathrooms = unit_data['UnitBathrooms'].to_i
            unit.sqft = unit_data['MaxSquareFeet'].to_i
            unit.market_rent = unit_data['MarketRent'].to_f
            unit.occupancy = unit_data['UnitOccupancyStatus']
            unit.lease_status = unit_data['UnitLeasedStatus']
            unit.model = unit_data['UnitEconomicStatus'] == 'model'
          end

          return unit
        end

      end
    end
  end
end
