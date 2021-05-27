module Yardi
  module Voyager
    module Data
      class GuestCard
        require 'nokogiri'

        # REJECTED_CUSTOMER_TYPES = %w{guarantor cancelled other}
        ACCEPTED_CUSTOMER_TYPES = %w{applicant approved_applicant future_resident prospect canceled}
        RESIDENT_TYPES = %w{current_resident former_resident roommate spouse}
        REMOTE_DATE_FORMAT="%FT%T"

        ATTRIBUTES = [
          :property_id,
          :name_prefix, :first_name, :middle_name, :last_name,
          :prospect_id, :tenant_id, :third_party_id,
          :address1, :address2, :city, :state, :postalcode,
          :email,
          :phones,
          :expected_move_in, :lease_from, :lease_to,
          :actual_move_in, :floorplan, :unit, :rent, :bedrooms, :bathrooms,
          :preference_comment,
          :events,
          :first_comm,
          :record_type,
          :referral
        ]

        attr_accessor *ATTRIBUTES
        attr_accessor :debug

        def self.from_lead(lead, yardi_property_id)
          card = GuestCard.new
          card.name_prefix = lead.title
          card.first_name = lead.first_name
          card.middle_name = lead.middle_name
          card.last_name = lead.last_name
          card.prospect_id = lead.remoteid
          card.property_id = yardi_property_id
          card.email = lead.email
          card.phones = self.voyager_phones_from_lead(lead)
          card.expected_move_in = lead.preference.move_in.strftime("%Y-%m-%d") rescue nil
					card.first_comm = lead.first_comm
					card.bedrooms = lead&.preference&.beds
					card.bathrooms = lead&.preference&.baths
          card.preference_comment = lead.preference.notes
          card.events = Yardi::Voyager::Data::GuestCardEvent.from_lead_events(lead)
          return card
        end

        def self.from_GetYardiGuestActivity(data, filter=true)
          self.from_api_response(response: data, method: 'GetYardiGuestActivity_Login') do |response_data|
            ( response_data.dig('LeadManagement', 'Prospects', 'Prospect') || [] ).
               map{|record| GuestCard.from_guestcard_node(record, filter)}.flatten
          end
        end

        def self.from_GetYardiGuestActivitySearch(data, filter=true)
          self.from_api_response(response: data, method: 'GetYardiGuestActivity_Search') do |response_data|

            messages = response_data.fetch("Messages",false)

            err = false
            if messages
              if messages['Message'].is_a?(Hash)
                msgs = [messages['Message']]
              else
                msgs = messages['Message']
              end

              msgs.map! do |m|
                next if m.is_a?(String)
                [m.fetch('messageType','Default'), m.fetch('__content__', 'Default')]
              end
              msgs.compact!

              if msgs.any?{|m| m[0] == 'Error'}
                if msgs.any?{|m| m[1].match('No guests')}
                  err = true
                else
                  error_messages = msgs.map{|m| "#{m[0]}: #{m[1]}"}.join(';')
                  raise "ImportYardiGuest server error: #{error_messages}"
                end
              end
            end

            record = response_data.dig('LeadManagement', 'Prospects', 'Prospect')

            if err || record.empty?
              nil
            else
              GuestCard.from_guestcard_node(record, filter)
            end
          end
        end

        def self.from_GetYardiGuestActivityDateRange(data)
          self.from_api_response(response: data, method: 'GetYardiGuestActivity_DateRange') do |response_data|
            ( response_data.dig('LeadManagement', 'Prospects', 'Prospect') || [] ).
               map{|record| GuestCard.from_guestcard_node(record)}.flatten
          end
        end

        # Return [ Lead ] with an updated remoteid from Yardi Voyager
        def self.from_ImportYardiGuest(response:, lead:)
          self.from_api_response(response: response, method: 'ImportYardiGuest_Login') do |response_data|
            messages = response_data.fetch("Messages",false)
            if messages
              if messages['Message'].is_a?(Hash)
                msgs = [messages['Message']]
              else
                msgs = messages['Message']
              end

              msgs.map! do |m|
                next if m.is_a?(String)
                [m.fetch('messageType','Default'), m.fetch('__content__', 'Default')]
              end
              msgs.compact!

              if msgs.any?{|m| m[0] == 'Error'}
                error_messages = msgs.map{|m| "#{m[0]}: #{m[1]}"}.join(';')
                raise "ImportYardiGuest server error: #{error_messages}"
              end

              remoteid = msgs.map{|m| m[1].match(/CustomerID: ([a-z0-9]+)$/)[1] rescue nil}.compact.first
            end
            lead.remoteid = remoteid if remoteid.present?
            lead
          end
        end

        def self.from_api_response(response:, method:, &block)
          root_node = nil

          case response
          when String
            begin
              data = JSON(response)
            rescue => e
              raise Yardi::Voyager::Data::Error.new("Invalid GuestCard JSON: #{e}")
            end
          when Hash
            data = response
          else
            raise Yardi::Voyager::Data::Error.new("Invalid GuestCard data. Should be JSON string or Hash")
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

            messages = root_node.fetch("Messages",false)
            if messages
              message_data = messages["Message"]
              messages_array = []
              case message_data.class
              when Array
                messages_array = message_data
              when Hash
                messages_array = [message_data]
              end
              err_msg = ""
              messages_array.each do |m|
                err_msg += [m.fetch("messageType",'Default'), m.fetch("__content__", "Unknown error")].join(': ')
              end

              Rails.logger.warn("Yardi::Voyager API Messages: #{err_msg}")
            end
          rescue => e
            raise Yardi::Voyager::Data::Error.new("Error encountered processing Voyager Response: #{e} ---- Response Data: #{data}")
          end

          return yield(root_node)
        end

        def self.from_guestcard_node(data, filter=true)
          prospects = []

          # Data schema returned by Yardi Voyager is inconsistent between
          # GetYardiGuestActivity_Login and GetYardiGuestActivity_DateRange
          prospect_record = nil
          if data.is_a?(Array)
            prospect_record = data[1]['Customer']
            prospect_preferences = {}
            prospect_events = {}
          else
            prospect_record = data['Customers']['Customer']
            prospect_preferences = data.fetch( 'CustomerPreferences', {} )
            prospect_events = data.fetch( 'Events', {} )
          end

          [ prospect_record ].flatten.compact.each do |pr|
            # Abort processing if this is not a wanted Customer type
            record_type = pr['Type']
            next if filter && !ACCEPTED_CUSTOMER_TYPES.include?(record_type)

            prospect = GuestCard.new
            prospect.record_type = record_type

            pr['Identification'].tap do |identification|
              ( identification ).each do |ident|
                val = ident['IDValue']
                case ident['IDType']
                when 'ProspectID'
                  prospect.prospect_id = val
                when 'TenantID'
                  prospect.tenant_id = val
                when 'PropertyID'
                  prospect.property_id = val
                when 'ThirdPartyID'
                  prospect.third_party_id = val
                end
              end
            end if pr['Identification']

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
              if prospect.expected_move_in.present? && prospect.expected_move_in < 100.years.ago
                # Guard against invalid data
                prospect.expected_move_in = nil
              end
              prospect.lease_from = ( Date.parse(lease['LeaseFromDate']) rescue nil)
              prospect.lease_to = ( Date.parse(lease['LeaseToDate']) rescue nil)
              prospect.actual_move_in =( Date.parse(lease['ActualMoveIn']) rescue nil)
              if prospect.actual_move_in.present? && prospect.actual_move_in < 100.years.ago
                # Guard against invalid data
                prospect.actual_move_in = nil
              end
              prospect.rent = ( lease['CurrentRent'] || 1 ).to_i
            end if pr['Lease']
            prospect.expected_move_in ||= prospect_preferences['TargetMoveInDate']
            prospect.floorplan = prospect_preferences['DesiredFloorplan']
            prospect_preferences['DesiredUnit'].tap do |unit|
              prospect.unit = (unit['MarketingName']) rescue nil
            end if prospect_preferences['DesiredUnit']
            prospect_preferences['DesiredRent'].tap do |rent|
              prospect.rent = rent['Exact'].to_i
            end if prospect_preferences['DesiredRent']
            prospect_preferences['DesiredNumBedrooms'].tap do |bedrooms|
              prospect.bedrooms = ( bedrooms['Exact'] || 1 ).to_i
            end if prospect_preferences['DesiredNumBedrooms']
            prospect_preferences['Comment'].tap do |comment|
              # Note that Yardi Voyager data in the Comment node is often truncated.
              # Full text appears in the Events node children.
              prospect.preference_comment = ([ comment ] || []).flatten.compact.join(' ')
            end if prospect_preferences['Comment']

            if (events = prospect_events.try(:first).try(:last))
              prospect.events = [events].flatten.compact.map do |e|
                event = GuestCardEvent.new
                event.remoteid = e["EventID"]["IDValue"]
                event.event_type = e["EventType"]
                event.date = e["EventDate"]
                event.reasons = e["EventReasons"]
                event.first_contact = e["FirstContact"]
                event.comments = e["Comments"]
                event.transaction_source = e["TransactionSource"]
                event
              end

              # Lacking a GuestCard creation date, use the first recorded EventDate as the first_comm date
              first_comm = prospect.events.sort_by{|e| e.date}.first
              prospect.first_comm = ( DateTime.parse(first_comm.date) rescue nil )

              # Assign Referral from first contact event
              prospect.referral = (first_comm.transaction_source rescue nil) if first_comm.first_contact == "true"
            end

            prospects << prospect
          end

          return prospects
        end

        def self.to_xml_2(lead:, include_events: false)
          organization = Yardi::Voyager::Api::Configuration.new.vendorname
          agent = lead.creditable_agent ||
                  User.new(profile: UserProfile.new(first_name: 'None', last_name: 'None'))
          propertyid = lead.property.voyager_property_code
          customer = GuestCard.from_lead(lead, propertyid)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.LeadManagement('xmlns' => '') {
              xml.Prospects {
                xml.Prospect {
                  xml.Customers {
                    xml.Customer('Type' => lead_guestcard_type(lead)) {
                      if lead.remoteid.present?
                        xml.Identification('IDType' => 'ProspectID', 'IDValue' => lead.remoteid)
                      else
                        xml.Identification('IDType' => 'ThirdPartyID', 'IDValue' => lead.shortid, 'OrganizationName' => organization)
                      end

                      xml.Identification('IDType' => 'PropertyID', 'IDValue' => propertyid, 'OrganizationName' => 'Yardi')

                      xml.Name {
                        xml.NamePrefix customer.name_prefix
                        xml.FirstName customer.first_name || ' '
                        xml.MiddleName customer.middle_name
                        xml.LastName customer.last_name || ' '
                      }

                      customer.phones.compact.each do |phone|
                        if phone.first.present?
                          xml.Phone('PhoneType' => phone[0]) {
                            xml.PhoneNumber phone[1]
                          } if phone[1].present?
                        end
                      end

                      xml.Email customer.email
                      if customer.expected_move_in.present? && customer.expected_move_in > ( lead.first_comm + 1.week )
                        xml.Lease {
                          xml.ExpectedMoveInDate customer.expected_move_in
                        }
                      end
                    }
                  }

                  xml.CustomerPreferences {
                    if customer.expected_move_in.present? &&
                      customer.expected_move_in > ( lead.first_comm + 1.week )
                      xml.TargetMoveInDate customer.expected_move_in
                    end
                    if ( customer.bedrooms || 0 ) > 0
                      xml.DesiredNumBedrooms('Exact' => customer.bedrooms.to_i.to_s)
                    end
                    if ( customer.bathrooms || 0 ) > 0
                      xml.DesiredNumBathrooms('Exact' => customer.bathrooms.round.to_s)
                    end
                  } if customer.has_preferences?

                  xml.Events {
                    customer.events.each do |event|
                      xml.Event('EventType' =>event.event_type, 'EventDate' => event.date.strftime(REMOTE_DATE_FORMAT) ) {
                        if event.idtype.present?
                          xml.EventID('IDValue' => event.remoteid, 'IDType' => event.idtype)
                        else
                          xml.EventID('IDValue' => event.remoteid)
                        end
                        xml.Agent {
                          xml.AgentName {
                            xml.FirstName event.agent.fetch(:first_name, '')
                            xml.LastName event.agent.fetch(:last_name, '')
                          }
                        }
                        xml.EventReasons event.reasons
                        xml.FirstContact event.first_contact
                        xml.Comments event.comments
                        xml.TransactionSource event.transaction_source
                      }
                    end
                  } if include_events && customer.events.present?

                } # end xml.Prospect
              } # end xml.Prospects
            } # end xml.LeadManagement
          end # Builder

          # Return XML without XML doctype or carriage returns
          return builder.doc.root.serialize(save_with:0)
        end

        def self.voyager_phones_from_lead(lead)
          phones = {office: nil, home: nil, cell: nil}
          [[lead.phone1, lead.phone1_type],[lead.phone2, lead.phone2_type]].each do |phone|
            pn, pt = phone
            next unless pn.present?
            case pt
            when 'Cell'
              phones[:cell] = pn
            when 'Home'
              phones[:home] = pn
            when 'Work'
              phones[:office] = pn
            else
              if phones[:home].present?
                phones[:office] ||= pn
              else
                phones[:home] ||= pn
              end
            end
          end
          phones[:office] ||= ( phones[:home] || phones[:cell] )
          phones[:cell] ||= (phones[:home] || phones[:office])
          phones[:home] ||= (phones[:cell] || phones[:office])
          return phones.to_a
        end

        def self.to_csv(guestcards)
          attrs = GuestCard::ATTRIBUTES
          row = attrs.map(&:to_s)
          csv_str = CSV.generate do |csv|
            csv << row
            guestcards.each{|card|
              csv << attrs.map{|col| card.send(col) }
            }
          end
          return csv_str
        end

				def has_preferences?
					( expected_move_in.present? &&
						expected_move_in > ( first_comm + 1.week ) ) ||
					bathrooms.present? || bedrooms.present?
				end

        def prospect?
          ACCEPTED_CUSTOMER_TYPES.include?(record_type)
        end

        def resident?
          RESIDENT_TYPES.include?(record_type)
        end

        def summary
          <<~EOS
            == Yardi Voyager GuestCard ==
            * Type: #{@record_type}
            * Name: #{@name_prefix} #{@first_name} #{@middle_name} #{@last_name}
            * Address: #{@address1} #{@address2} #{@city}, #{@state} #{@postalcode}
            * Phones: #{@phones.inspect}
            * Property ID: #{@property_id}
            * Prospect ID: #{@prospect_id}
            * Tenant ID: #{@tenant_id}
            * Third Party ID: #{@third_party_id}
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



        def self.to_xml_1(lead:)
          organization = Yardi::Voyager::Api::Configuration.new.vendorname
          agent = lead.user ||
                  lead.property.primary_agent ||
                  User.new(first_name: 'None', last_name: 'None')
          propertyid = lead.property.voyager_property_code
          customer = GuestCard.from_lead(lead, propertyid)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.LeadManagement('xmlns' => '') {
              xml.Prospects {
                xml.Prospect {
                  xml.Customers {
                    xml.Customer('Type' => lead_guestcard_type(lead)) {
                      if lead.remoteid.present?
                        xml.Identification('IDType' => 'ProspectID', 'IDValue' => lead.remoteid)
                      end
                      xml.Identification('IDType' => 'ThirdPartyID', 'IDValue' => lead.shortid, 'OrganizationName' => organization)
                      xml.Identification('IDType' => 'PropertyID', 'IDValue' => propertyid, 'OrganizationName' => 'Yardi')
                      #xml.Identification('IDType' => 'NoMiddleName', 'IDValue' => 'true')
                      xml.Name {
												xml.NamePrefix customer.name_prefix
                        xml.FirstName customer.first_name || ' '
                        xml.MiddleName customer.middle_name
                        xml.LastName customer.last_name || ' '
                      }
											#xml.Address('AddressType' => 'current') {
												#xml.AddressLine1
												#xml.AddressLine2
												#xml.City
												#xml.State
												#xml.PostalCode
											#}
                      customer.phones.compact.each do |phone|
                        if phone.first.present?
                          xml.Phone('PhoneType' => phone[0]) {
														xml.PhoneNumber phone[1]
                          }
                        end
                      end
                      xml.Email customer.email
                      if customer.expected_move_in.present? &&
                        customer.expected_move_in > ( lead.first_comm + 1.week )
                        xml.Lease {
                          xml.ExpectedMoveInDate customer.expected_move_in
                        }
                      end
                    }
                  }
                  xml.CustomerPreferences {
                    if customer.expected_move_in.present? &&
                      customer.expected_move_in > ( lead.first_comm + 1.week )
                        xml.TargetMoveInDate customer.expected_move_in
                    end
                    if ( lead.preference.try(:beds) || 0 ) > 0
                      xml.DesiredNumBedrooms('Exact' => lead.preference.beds.to_i.to_s)
                    end
                    if ( lead.preference.try(:baths) || 0 ) > 0
                      xml.DesiredNumBathrooms('Exact' => lead.preference.baths.round.to_s)
                    end

                    # Voyager doesn't like DesiredRent elements for some reason
                    #
                    #if (lead.preference.try(:max_price) || 0) > 0
                      #xml.DesiredRent('Exact' => lead.preference.max_price.to_s)
                    #end

                    # Voyager doesn't like DesiredFloorplan elements for some reason
                    #
                    #if lead.preference.unit_type.present? && lead.preference.unit_type.remoteid.present?
                      #xml.DesiredFloorplan lead.preference.unit_type.name
                    #end
                  }
                  unless lead.remoteid.present?
                    # New GuestCards in Voyager must provide at least one Event record.
                    xml.Events {
                      xml.Event('EventType' => 'Other', 'EventDate' => lead.first_comm.strftime(REMOTE_DATE_FORMAT) ) {
                        xml.EventID('IDValue' => '')
                        xml.Agent {
                          xml.AgentName {
                            xml.FirstName agent.first_name
                            xml.LastName agent.last_name
                          }
                        }
                        xml.EventReasons 'Spoke to'
                        xml.FirstContact 'true'
                        xml.Comments("%s (Bluesky Lead from %s/%s)" % [lead.preference.notes, lead.source.try(:name), lead.referral])
                        xml.TransactionSource 'Referral'
                      }
                    }
                  end
                }
              }
            }
          end

          # Return XML without XML doctype or carriage returns
          return builder.doc.root.serialize(save_with:0)
        end #to_xml_2

        def self.lead_guestcard_type(lead)
          return case lead.state.to_s
            when 'open', 'prospect', 'showing', 'application', 'approved'
              'prospect'
            when 'denied'
              'canceled'
            when 'resident'
              'current_resident'
            when 'exresident'
              'former_resident'
            when 'disqualified'
              'canceled'
            when 'abandoned'
              'canceled'
            when 'future'
              'future_resident'
            else
              'prospect'
            end
        end


      end# Yardi::Voyager::Data::GuestCard
    end # Yardi::Voyager::Data
  end # Yardi::Yoyager
end # Yardi
