module Yardi
  module Voyager
    module Api
      class GuestCards < Base

        # Return GuestCards for the given property id
        def getGuestCards(propertyid, start_date: nil, end_date: DateTime.now, filter: true)
          if start_date.present?
            return getGuestCardsDateRange(propertyid, start_date: start_date, end_date: end_date)
          end

          request_options = {
            method: 'GetYardiGuestActivity_Login',
            resource: 'ItfILSGuestCard.asmx',
            propertyid: propertyid
          }
          begin
            response = getData(request_options)
            guestcards = Yardi::Voyager::Data::GuestCard.from_GetYardiGuestActivity(response.parsed_response, filter)
          rescue => e
            msg = "#{format_request_id} Yardi::Voyager::Api::Guestcards encountered an error fetching data. #{e} -- #{e.backtrace}"
            Rails.logger.error msg
            ErrorNotification.send(StandardError.new(msg), {propertyid: propertyid})
            return []
          end
          return guestcards
        end

        # Return GuestCards for the given property id and date window
        def getGuestCardsDateRange(propertyid, start_date: nil, end_date: DateTime.now)
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
            msg = "#{format_request_id} Yardi::Voyager::Api::Guestcards encountered an error fetching data. #{e} -- #{e.backtrace}"
            Rails.logger.error msg
            ErrorNotification.send(StandardError.new(msg), {propertyid: propertyid})
            return []
          end
          return guestcards
        end

        def sendGuestCard(propertyid:, lead:)
          request_options = {
            method: 'ImportYardiGuest_Login',
            resource: 'ItfILSGuestCard.asmx',
            propertyid: propertyid,
            xml: Yardi::Voyager::Data::GuestCard.to_xml(lead: lead, propertyid: propertyid)
          }
          begin
            response = getData(request_options)
            updated_lead = Yardi::Voyager::Data::GuestCard.from_ImportYardiGuest(response: response.parsed_response, lead: lead)
            if updated_lead.present?
              Rails.logger.warn "Yardi::Voyager::Api Submitted Lead:#{updated_lead.id} as Voyager GuestCard:#{updated_lead.remoteid}"
            else
              Rails.logger.error "Yardi::Voyager::Api Submission of Lead[#{lead.id}] as Voyager GuestCard did not return a Lead as expected"
            end
          rescue => e
            msg =  "#{format_request_id} Yardi::Voyager::Api::Guestcards encountered an error fetching data. #{e} -- #{e.backtrace}"
            Rails.logger.error msg
            ErrorNotification.send(StandardError.new(msg), {lead_id: lead.id, property_id: lead.property_id})
            return lead
          end
          return updated_lead
        end

        # Call template method depending on method
        def request_template(method=nil)
          case method
          when 'GetYardiGuestActivity_Login'
            template_GetYardiGuestActivity_Login
          when 'GetYardiGuestActivity_DateRange'
            template_GetYardiGuestActivity_DateRange
          when 'ImportYardiGuest_Login'
            template_ImportYardiGuest_Login
          else
            template_GetYardiGuestActivity_Login
          end
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
