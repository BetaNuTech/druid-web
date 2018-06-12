module Yardi
  module Voyager
    module Api
      class GuestCards < Base

        # Return GuestCards for the given property id
        def getGuestCards(propertyid)
          request_options = {
            method: 'GetYardiGuestActivity_Login',
            resource: 'ItfILSGuestCard.asmx',
            propertyid: propertyid
          }
          begin
            response = getData(request_options)
            guestcards = Yardi::Voyager::Data::GuestCard.from_GetYardiGuestActivity(response.parsed_response)
          rescue => e
            Rails.logger.error "Yardi::Voyager::Api::Guestcards encountered an error fetching data. #{e}"
            return []
          end
          return guestcards
        end

	def request_template(method=nil)
	  case method
	  when 'GetYardiGuestActivity_Login'
	    template_GetYardiGuestActivity_Login
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

          # Remove all line-feeds. Line-feeds kill the server for some reason.
          body_template = body_template.gsub(/[\n\r]+/,'')

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

          # Remove all line-feeds. Line-feeds kill the server for some reason.
          body_template = body_template.gsub(/[\n\r]+/,'')

          return body_template
        end
      end
    end
  end
end
