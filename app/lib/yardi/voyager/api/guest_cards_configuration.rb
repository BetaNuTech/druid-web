module Yardi
  module Voyager
    module Api
      class GuestCardsConfiguration < Base

        # Return GuestCards for the given property id
        def getConfig(option=nil)
          request_options = {
            service: 'ItfILSGuestCard',
            method: 'GetILSGuestCardConfiguration',
            resource: 'ItfILSGuestCard.asmx'
          }
          xml_data = getData(request_options)
          return xml_data
        end

        def request_template(method=nil)
          case method
          when 'GetYardiGuestActivity_Login'
            template_GetILSGuestCardConfiguration
          else
            template_GetILSGuestCardConfiguration
          end
        end

        def template_GetILSGuestCardConfiguration
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
