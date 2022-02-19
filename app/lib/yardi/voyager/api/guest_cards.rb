module Yardi
  module Voyager
    module Api
      class GuestCards < Base

        # Return GuestCards for the given property id
        def getGuestCards(propertyid, start_date: nil, end_date: DateTime.current, filter: true)
          if start_date.present?
            return getGuestCardsDateRange(propertyid, start_date: start_date, end_date: end_date)
          end

          request_options = {
            service: 'ItfILSGuestCard',
            method: 'GetYardiGuestActivity_Login',
            resource: 'ItfILSGuestCard.asmx',
            propertyid: propertyid
          }
          begin
            response = getData(request_options)
            guestcards = Yardi::Voyager::Data::GuestCard.from_GetYardiGuestActivity(response.parsed_response, filter)
          rescue => e
            msg = "#{format_request_id} Yardi::Voyager::Api::Guestcards.getGuestCards encountered an error fetching data. #{e}"
            full_msg = "#{msg} -- #{e.backtrace}"
            Rails.logger.error full_msg
            create_event_note(propertyid: propertyid, incoming: true, message: full_msg, error: true)
            #ErrorNotification.send(StandardError.new(msg), {propertyid: propertyid})
            return []
          end
          return guestcards
        end

        # Find a GuestCard
        #
        # Ex: getGuestCard('maplebr', params: {third_party_id: "XXX"}, options: {full_params: true})
        #
        # Supported Params: {third_party_id:, first_name:, last_name:, email_address:, phone_number:, date_of_birth:, federal_id: }
        def getGuestCard(propertyid, params: {}, options: {full_params: true} )
          all_search_params = {third_party_id: nil, first_name: nil, last_name: nil, email_address: nil, phone_number: nil, date_of_birth: nil, federal_id: nil }
          search_params = params
          if options[:full_params] == true
            search_params = all_search_params.merge(params)
          end

          if (invalid_params = search_params.keys - all_search_params.keys).present?
            raise "Invalid param for Yardi::Voyager::Api::GuestCards.getGuestCard: #{invalid_params}"
          end

          xml_params = search_params.to_a.inject("") do |memo, obj|
            memo << "<%{key}>%{value}</%{key}>" % {key: obj[0].to_s.classify, value: obj[1]}
            memo
          end
          request_options = {
            method: 'GetYardiGuestActivity_Search',
            resource: 'ItfILSGuestCard.asmx',
            propertyid: propertyid,
            xml_params: xml_params
          }.merge(search_params)
          begin
            response = getData(request_options)
            guestcards = Yardi::Voyager::Data::GuestCard.from_GetYardiGuestActivitySearch(response.parsed_response, false)
          rescue => e
            msg = "#{format_request_id} Yardi::Voyager::Api::Guestcards.getGuestCard encountered an error fetching data. #{e}"
            full_msg = "#{msg} -- #{e.backtrace}"
            Rails.logger.error full_msg
            create_event_note(propertyid: propertyid, incoming: true, message: full_msg, error: true)
            return []
          end
          return guestcards
        end

        # Return GuestCards for the given property id and date window
        def getGuestCardsDateRange(propertyid, start_date: nil, end_date: DateTime.current)
          request_options = {
            method: 'GetYardiGuestActivity_DateRange',
            resource: 'ItfILSGuestCard.asmx',
            propertyid: propertyid,
            from_date: start_date.strftime(Yardi::Voyager::Data::GuestCard::REMOTE_DATE_FORMAT),
            to_date: end_date.strftime(Yardi::Voyager::Data::GuestCard::REMOTE_DATE_FORMAT)
          }

          begin
            response = getData(request_options)
            guestcards = Yardi::Voyager::Data::GuestCard.from_GetYardiGuestActivityDateRange(response.parsed_response)
          rescue => e
            msg = "#{format_request_id} Yardi::Voyager::Api::Guestcards.getGuestCardsDateRange encountered an error fetching data. #{e}"
            full_msg = "#{msg} -- #{e.backtrace}"
            Rails.logger.error full_msg
            create_event_note(propertyid: propertyid, incoming: true, message: full_msg, error: true)
            return []
          end
          return guestcards
        end

        def sendGuestCard(lead:, dry_run: false, include_events: false, version: 2)
          propertyid = lead.property.voyager_property_code
          case version
          when 2
            payload = Yardi::Voyager::Data::GuestCard.to_xml_2(lead: lead, include_events: include_events)
          when 1
            payload = Yardi::Voyager::Data::GuestCard.to_xml_1(lead: lead)
          else
            payload = Yardi::Voyager::Data::GuestCard.to_xml_2(lead: lead, include_events: include_events)
          end

          request_options = {
            method: 'ImportYardiGuest_Login',
            resource: 'ItfILSGuestCard.asmx',
            propertyid: propertyid,
            xml: payload
          }
          begin
            last_remoteid = lead.remoteid
            if dry_run
              response = getData(request_options, dry_run: true)
              updated_lead = lead
            else
              response = getData(request_options, dry_run: false)
              updated_lead = Yardi::Voyager::Data::GuestCard.from_ImportYardiGuest(response: response.parsed_response, lead: lead)
              if include_events
                updated_lead = updateLeadEvents(propertyid: propertyid, lead: updated_lead)
              end
            end
            if updated_lead.present? && updated_lead.remoteid != last_remoteid
              msg = "Yardi::Voyager::Api Submitted Lead:#{updated_lead.id} as Voyager GuestCard:#{updated_lead.remoteid}"
              Rails.logger.warn msg
              create_event_note(propertyid: propertyid, notable: lead, incoming: false, message: msg, error: false)
            else
              msg = "Yardi::Voyager::Api Submission of Lead[#{lead.id}] as Voyager GuestCard did not return a Lead as expected"
              Rails.logger.error msg
              create_event_note(propertyid: propertyid, notable: lead, incoming: false, message: msg, error: true)
            end
          rescue => e
            msg =  "#{format_request_id} Yardi::Voyager::Api::Guestcards.sendGuestCard encountered an error fetching data. #{e}"
            full_msg = msg + " -- #{e.backtrace}"
            Rails.logger.error msg
            create_event_note(propertyid: propertyid, notable: lead, incoming: false, message: full_msg, error: true)
            return lead
          end
          return updated_lead
        end

        def updateLeadEvents(propertyid:, lead:)
          # Do not update associated events if there are issues with the lead
          unless lead.valid?
            msg =  "#{format_request_id} Yardi::Voyager::Api::GuestCards declines to update events due to Lead validation errors: #{lead.errors.to_a.join('; ')}"
            Rails.logger.error msg
            create_event_note(propertyid: propertyid, notable: lead, incoming: false, message: msg, error: true)
            return lead
          end

          guestcard = getGuestCard(propertyid, params: {third_party_id: lead.shortid})&.first
          unless guestcard.present?
            msg =  "#{format_request_id} Yardi::Voyager::Api::GuestCards cannot find associated GuestCard for Lead[#{lead.id}]"
            Rails.logger.error msg
            create_event_note(propertyid: propertyid, notable: lead, incoming: false, message: msg, error: true)
            return lead
          end

          msg =  "#{format_request_id} Yardi::Voyager::Api::GuestCards will update Lead[#{lead.id}] event remote ids"
          Rails.logger.warn msg

          event_re = /\[([A-Za-z]+):([^\]]+)\]/
          events_created = 0
          guestcard.events.each do |guestcard_event|
            event = nil
            if (bluesky_event_id = guestcard_event.comments.match(event_re))
              event_reference, event_class, event_id = bluesky_event_id.to_a
              begin
                case event_class
                when 'LeadTransition'
                  event = LeadTransition.find event_id
                when 'ScheduledAction'
                  event = ScheduledAction.find event_id
                else
                  raise ActiveRecord::RecordNotFound
                end
              rescue ActiveRecord::RecordNotFound
                msg =  "#{format_request_id} Yardi::Voyager::Api::GuestCards cannot find #{event_reference} for GuestCard[#{guestcard.prospect_id}] Event[#{guestcard_event.remoteid}] for Bluesky Lead[#{lead.id}]"
                Rails.logger.error msg
                create_event_note(propertyid: propertyid, notable: lead, incoming: false, message: msg, error: true)
              end
            end

            if event.nil?
              msg = "#{format_request_id} Voyager Event[#{guestcard_event.remoteid}] for Guestcard[#{guestcard.prospect_id}] does not reference a valid Bluesky Event"
              Rails.logger.info msg
              #create_event_note(propertyid: propertyid, notable: lead, incoming: false, message: msg, error: true)
              next
            end

            last_remoteid  = event.remoteid
            event.remoteid = guestcard_event.remoteid
            if event.save
              msg = "#{format_request_id} #{event.class.name}[#{event.id}] remoteid set to '#{event.remoteid}'"
              Rails.logger.info msg
              if last_remoteid != event.remoteid
                events_created += 1
              end
            else
              msg = "#{format_request_id} #{event.class.name}[#{event.id}] could not be saved: #{event.errors.to_a.join('; ')}"
              Rails.logger.warn msg
              create_event_note(propertyid: propertyid, notable: lead, incoming: false, message: msg, error: true)
            end

          end

          if events_created > 0
            msg = "Yardi::Voyager::Api::GuestCards submitted #{events_created} events for Lead[#{lead.id}] to Guestcard[#{lead.remoteid}]"
            create_event_note(propertyid: propertyid, notable: lead, incoming: false, message: msg, error: false)
          end

          return lead
        end

        # Call template method depending on method
        def request_template(method=nil)
          case method
          when 'GetYardiGuestActivity_Login'
            template_GetYardiGuestActivity_Login
          when 'GetYardiGuestActivity_DateRange'
            template_GetYardiGuestActivity_DateRange
          when 'GetYardiGuestActivity_Search'
            template_GetYardiGuestActivity_Search
          when 'ImportYardiGuest_Login'
            template_ImportYardiGuest_Login
          else
            template_GetYardiGuestActivity_Login
          end
        end

        def template_GetYardiGuestActivity_Search
          body_template = <<~EOS
            <?xml version="1.0" encoding="utf-8"?>
            <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
              <soap:Body>
                <%{method} xmlns="http://tempuri.org/YSI.Interfaces.WebServices/ItfILSGuestCard">
                  <UserName>%{username}</UserName>
                  <Password>%{password}</Password>
                  <ServerName>%{servername}</ServerName>
                  <Database>%{database}</Database>
                  <Platform>%{platform}</Platform>
                  <YardiPropertyId>%{propertyid}</YardiPropertyId>
                  <InterfaceEntity>%{vendorname}</InterfaceEntity>
                  <InterfaceLicense>%{license}</InterfaceLicense>
                  %{xml_params}
                </%{method}>
              </soap:Body>
            </soap:Envelope>
          EOS

          body_template = cleanup_xml(body_template)

          return body_template
        end

        def template_GetYardiGuestActivity_Login
          body_template = <<~EOS
            <?xml version="1.0" encoding="utf-8"?>
            <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
              <soap:Body>
                <%{method} xmlns="http://tempuri.org/YSI.Interfaces.WebServices/ItfILSGuestCard">
                  <UserName>%{username}</UserName>
                  <Password>%{password}</Password>
                  <ServerName>%{servername}</ServerName>
                  <Database>%{database}</Database>
                  <Platform>%{platform}</Platform>
                  <YardiPropertyId>%{propertyid}</YardiPropertyId>
                  <InterfaceEntity>%{vendorname}</InterfaceEntity>
                  <InterfaceLicense>%{license}</InterfaceLicense>
                </%{method}>
              </soap:Body>
            </soap:Envelope>
          EOS

          body_template = cleanup_xml(body_template)

          return body_template
        end

        def template_GetYardiGuestActivity_DateRange
          body_template = <<~EOS
            <?xml version="1.0" encoding="utf-8"?>
            <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
              <soap:Body>
                <%{method} xmlns="http://tempuri.org/YSI.Interfaces.WebServices/ItfILSGuestCard">
                  <UserName>%{username}</UserName>
                  <Password>%{password}</Password>
                  <ServerName>%{servername}</ServerName>
                  <Database>%{database}</Database>
                  <Platform>%{platform}</Platform>
                  <YardiPropertyId>%{propertyid}</YardiPropertyId>
                  <InterfaceEntity>%{vendorname}</InterfaceEntity>
                  <InterfaceLicense>%{license}</InterfaceLicense>
                  <FromDate>%{from_date}</FromDate>
                  <ToDate>%{to_date}</ToDate>
                </%{method}>
              </soap:Body>
            </soap:Envelope>
          EOS

          body_template = cleanup_xml(body_template)

          return body_template
        end
        def template_GetYardiGuestActivity_Login
          body_template = <<~EOS
            <?xml version="1.0" encoding="utf-8"?>
            <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
              <soap:Body>
                <%{method} xmlns="http://tempuri.org/YSI.Interfaces.WebServices/ItfILSGuestCard">
                  <UserName>%{username}</UserName>
                  <Password>%{password}</Password>
                  <ServerName>%{servername}</ServerName>
                  <Database>%{database}</Database>
                  <Platform>%{platform}</Platform>
                  <YardiPropertyId>%{propertyid}</YardiPropertyId>
                  <InterfaceEntity>%{vendorname}</InterfaceEntity>
                  <InterfaceLicense>%{license}</InterfaceLicense>
                </%{method}>
              </soap:Body>
            </soap:Envelope>
          EOS

          body_template = cleanup_xml(body_template)

          return body_template
        end

        def template_ImportYardiGuest_Login
          body_template = <<~EOS
            <?xml version="1.0" encoding="utf-8"?>
            <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
              <soap:Body>
                <%{method} xmlns="http://tempuri.org/YSI.Interfaces.WebServices/ItfILSGuestCard">
									<UserName>%{username}</UserName>
									<Password>%{password}</Password>
									<ServerName>%{servername}</ServerName>
									<Database>%{database}</Database>
									<Platform>%{platform}</Platform>
									<YardiPropertyId>%{propertyid}</YardiPropertyId>
									<InterfaceEntity>%{vendorname}</InterfaceEntity>
									<InterfaceLicense>%{license}</InterfaceLicense>
									<XmlDoc>%{xml}</XmlDoc>
                </%{method}>
              </soap:Body>
            </soap:Envelope>
          EOS

          body_template = cleanup_xml(body_template)

          return body_template
        end

        def cleanup_xml(xml)
          # Remove all line-feeds. Line-feeds kill the server for some reason.
          return xml.gsub(/[\n\r]+/,'').gsub(/>[\s]+</,'><')
        end

      end
    end
  end
end
