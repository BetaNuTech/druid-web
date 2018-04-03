module Yardi
  module Voyager
    module Data
      class Prospect
        require 'nokogiri'

        REJECTED_CUSTOMER_TYPES = %w{guarantor cancelled other}
        ACCEPTED_CUSTOMER_TYPES = %w{applicant approved_applicant future_resident prospect}

        attr_accessor :debug,
          :name_prefix, :first_name, :middle_name, :last_name,
          :prospect_id, :third_party_id,
          :property_id,
          :address1, :address2, :city, :state, :postalcode,
          :email,
          :phones,
          :expected_move_in, :lease_from, :lease_to,
          :actual_move_in, :floorplan, :unit, :rent, :bedrooms,
          :preference_comment,
          :events,
          :record_type

        def self.from_GetYardiGuestActivity_json(data)
          root_node = nil

          case data
          when String
            begin
              data = JSON(data)
            rescue => e
              raise Data::Error.new("Invalid GuestCard JSON: #{e}")
            end
          when Hash
            # Noop
          else
            raise Data::Error.new("Invalid GuestCard data. Should be JSON string or Hash")
          end

          begin
            root_node = data["Envelope"]["Body"]["GetYardiGuestActivity_LoginResponse"]["GetYardiGuestActivity_LoginResult"]["LeadManagement"]["Prospects"]["Prospect"]
          rescue => e
              raise Data::Error.new("Invalid GuestCard data schema: #{e}")
          end

          #_first_lead_node = root_node.first
          #_first_lead = Prospect.from_guestcard_node(_first_lead_node)


          # TODO: Create Lead collection from Yardi Voyager GuestCard JSON
          raw_leads = root_node.map{|record| Prospect.from_guestcard_node(record)}.flatten

        end

        def self.from_guestcard_node(data)
          # TODO: Create Lead from GuestCard Hash
          prospects = []
          prospect_record = data['Customers']['Customer']
          prospect_preferences = data['CustomerPreferences']
          prospect_events = data['Events']

          [ prospect_record ].flatten.compact.each do |pr|
            binding.pry unless pr.is_a?(Hash)
            prospect = Prospect.new
            prospect.record_type = pr['Type']
            pr['Name'].tap do |name|
              prospect.name_prefix = name['NamePrefix']
              prospect.first_name = name['FirstName']
              prospect.middle_name = name['MiddleName']
              prospect.last_name = name['LastName']
            end if pr['Name']
            pr['Address'].tap do |address|
              prospect.address1 = address['AddressLine1']
              prospect.address2 = address['AddressLine2']
              prospect.city = address['City']
              prospect.state = address['State']
              prospect.postalcode = address['PostalCode']
            end if pr['Address']

            pr['Phone'].tap do |phones|
              prospect.phones = [ phones ].flatten.map do |phone|
                [ phone['PhoneType'], phone['PhoneNumber'] ]
              end
            end if pr['Phone']

            prospect.email = pr['Email']
            pr['Lease'].tap do |lease|
              prospect.expected_move_in = ( Date.parse(lease['ExpectedMoveInDate']) rescue nil)
              prospect.lease_from = ( Date.parse(lease['LeaseFromDate']) rescue nil)
              prospect.lease_to = ( Date.parse(lease['LeaseToDate']) rescue nil)
              prospect.actual_move_in =( Date.parse(lease['ActualMoveIn']) rescue nil)
              prospect.rent = lease['CurrentRent']
            end if pr['Lease']
            prospect.expected_move_in ||= prospect_preferences['TargetMoveInDate']
            prospect.floorplan = prospect_preferences['DesiredFloorplan']
            prospect_preferences['DesiredUnit'].tap do |unit|
              prospect.unit = (unit['MarketingName']) rescue nil
            end if prospect_preferences['DesiredUnit']
            prospect_preferences['DesiredRent'].tap do |rent|
              prospect.rent = rent['Exact']
            end if prospect_preferences['DesiredRent']
            prospect_preferences['DesiredNumBedrooms'].tap do |bedrooms|
              prospect.bedrooms = bedrooms['Exact']
            end if prospect_preferences['DesiredNumBedrooms']
            prospect_preferences['Comment'].tap do |comment|
              prospect.preference_comment = ([ comment ] || []).flatten.compact.join(' ')
            end if prospect_preferences['Comment']

            if (events = prospect_events.try(:first).try(:last))
              prospect.events = [ events ].flatten.compact.map{|e| "%s %s: %s" % [e["EventType"], e["EventDate"], e["Comments"]] }
            end

            #puts prospect.inspect if @debug

            if !ACCEPTED_CUSTOMER_TYPES.include?(prospect.record_type)
              #puts "*** REJECTED DUE TO TYPE" if @debug
              next
            end

            prospects << prospect
          end

          return prospects
        end

        def inspect
          <<~EOS
            == Prospect ==
            * Type: #{@record_type}
            * Name: #{@name_prefix} #{@first_name} #{@middle_name} #{@last_name}
            * Address: #{@address1}
                       #{@address2}
                       #{@city}
                       #{@state}
                       #{@postalcode}
            * Phones: #{@phones.inspect}
            * Preferences:
              - Expected Move In: #{@expected_move_in}
              - Lease From:       #{@lease_from}
              - Lease To:         #{@lease_to}
              - Actual Move In:   #{@actual_move_in}
              - FloorPlan:        #{@flooplan}
              - Unit:             #{@unit}
              - Rent:             #{@rent}
              - Bedrooms:         #{@bedrooms}
            * Comment: #{@preference_comment}
            * Events: #{@events.inspect}
          EOS
        end


      end
    end
  end
end
