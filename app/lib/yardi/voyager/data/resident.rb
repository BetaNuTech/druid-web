module Yardi
  module Voyager
    module Data
      class Resident
        require 'nokogiri'

        ATTRIBUTES = %i{ unit_name residentid status first_name middle_name last_name address1 address2 city state zip country phone1 phone1_type phone2 phone2_type email }

        attr_accessor *ATTRIBUTES
        attr_accessor :debug

        # TODO
        def self.from_GetResidentSearch(data)
          self.from_api_response(response: data, method: 'GetResident_Search') do |response_data|
            ( response_data.dig('CustomerSearch', 'Response', 'Customers', 'Customer') || [] ).
               map{|record| Resident.from_resident_node(record)}.flatten
          end
        end

        def self.from_api_response(response:, method:, &block)
          root_node = nil

          case response
          when String
            begin
              data = JSON(response)
            rescue => e
              raise Yardi::Voyager::Data::Error.new("Invalid Resident JSON: #{e}")
            end
          when Hash
            data = response
          else
            raise Yardi::Voyager::Data::Error.new("Invalid Resident data. Should be JSON string or Hash")
          end

          begin
            # Handle Server Error
            if (err_msg = data.dig("Envelope", "Body", "Fault")).present?
              raise Yardi::Voyager::Data::Error.new(err_msg.to_s)
            end

            root_node = data.dig("Envelope", "Body", "#{method}Response", "#{method}Result")
            if root_node.nil?
              Rails.logger.warn("Voyager Response contains no results ---- Response Data: #{data}")
              return yield({})
            end

            error_root = root_node.dig('CustomerSearch', 'Response', 'Customers', 'Customer')
            if error_root.is_a?(Hash) && error_root.fetch('ErrorMessages', false).is_a?(Hash)
              err_msg = error_root.dig('ErrorMessages','Error')
              Rails.logger.warn("Yardi::Voyager API Messages: #{err_msg}")
              raise Yardi::Voyager::Data::Error.new(err_msg)
              #return yield({})
            end
          rescue => e
            raise Yardi::Voyager::Data::Error.new("Error encountered processing Voyager Response: #{e}")
          end

          return yield(root_node)
        end

        def self.from_resident_node(record)
          status = record.dig('Identification', 'Status')&.match(/current/) ? 'current' : 'former'
          unit_name = record.dig('Lease','Identification','IDValue')

          mobile_number = record.dig('Phone','MobileNumber')
          home_number = record.dig('Phone','HomeNumber'),
          office_number = record.dig('Phone','OfficeNumber')
          phones = [mobile_number, home_number, office_number].flatten.compact.uniq
          phone1 = nil
          phone2 = nil
          if phones.size > 1
            phone1 = phones[0]
            phone2 = phones[1]
          else
            phone1 = phones.first
          end
          phone1_type = 'Cell' if phone1 && mobile_number == phone1
          phone1_type = 'Home' if phone1 && home_number == phone1
          phone1_type = 'Work' if phone1 && office_number == phone1
          phone2_type = 'Cell' if phone2 && mobile_number == phone2
          phone2_type = 'Home' if phone2 && home_number == phone2
          phone2_type = 'Work' if phone2 && office_number == phone2

          resident = Resident.new
          resident.unit_name = unit_name
          resident.residentid = record.dig('Identification', 'IDValue')
          resident.unit_name = unit_name
          resident.residentid = record.dig('Identification', 'IDValue')
          resident.status = status
          resident.first_name = record.dig('Name', 'FirstName')
          resident.middle_name = record.dig('Name', 'MiddleName')
          resident.last_name = record.dig('Name', 'LastName')
          resident.address1 = record.dig('Address','Address1')
          resident.address2 = record.dig('Address','Address2')
          resident.city = record.dig('Address','City')
          resident.state = record.dig('Address','State')
          resident.zip = record.dig('Address','PostalCode')
          resident.country = nil
          resident.phone1 = PhoneNumber.format_phone(phone1)
          resident.phone1_type =phone1_type
          resident.phone2 = phone2
          resident.phone2_type = phone2_type
          resident.email = record.dig('Address','email')

          resident
        end
      end

    end
  end
end
