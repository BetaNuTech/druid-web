module Yardi
  module Voyager
    module Api
      class Units < Base

        def getUnits(propertyid)
          # TODO
          request_options = {
            method: 'UnitAvailability_Login',
            resource: 'ItfILSGuestCard.asmx',
            propertyid: propertyid
          }
          begin
            response = getData(request_options)
            units = Yardi::Voyager::Data::Unit.from_UnitAvailability_Login(response.parsed_response)
          rescue => e
            msg = "#{format_request_id} Yardi::Voyager::Api::Units encountered an error fetching data. #{e} #{e.backtrace.to_a.first}"
            Rails.logger.error msg
            ErrorNotification.send(StandardError.new(msg))
            return []
          end
          return units
        end

        def request_template(method=nil)
          case method
          when 'UnitAvailability_Login'
            template_UnitAvailability_Login
          else
            template_UnitAvailability_Login
          end
        end

        def template_UnitAvailability_Login
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
      end
    end
  end
end
