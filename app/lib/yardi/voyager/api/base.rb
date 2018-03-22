module Yardi
  module Voyager
    module Api
      class Base
        include HTTParty
        attr_reader :configuration

        # Initialize with an optional Yardi::Voyager::Configuration instance
        def initialize(conf=nil)
          @configuration = conf || Yardi::Voyager::Api::Configuration.new(:env)
        end

        # Return GuestCards for the given property id
        def getLeads(propertyid)
          xml_data = getLeadsXML(propertyid)
        end

        # Return GuestCards XML for the provided property id
        def getLeadsXML(propertyid)
          method = 'GetYardiGuestActivity_Login'
          url = "%{api_root}/%{resource}" % {api_root: api_root, resource: 'ItfILSGuestCard.asmx' }
          headers = getLeads_headers(method: method)
          body = getLeads_body({method: method, propertyid: propertyid})

          puts " * Request URL:\n" + url
          puts " * Request Headers:\n" + headers.to_a.map{|h| "#{h[0]}: #{h[1]}"}.join("\n")
          puts " * Request Body:\n" + body
          result = fetch_xml(url: url, body: body, headers: headers)
          puts " * Response:\n" + result.to_s
        end

        def getLeads_headers(method:)
          {
            'Content-Type' => 'text/xml; charset=utf-8',
            'SOAPAction' => ( "http://%{host}/YSI.Interfaces.WebServices/ItfILSGuestCard/%{method}" %
                             {host: 'tempuri.org', method: method} )
          }
        end

        def getLeads_body(params)
          template_vars = config.merge(params)
          return getLeads_template % template_vars
        end

        def getLeads_template
          body_template = <<~EOS
            <?xml version="1.0" encoding="utf-8"?>
              <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                  xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
                <soap:Body>
                  <%{method}
                      xmlns="https://%{host}/YSI.Interfaces.WebServices/ItfILSGuestCard">
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

          return body_template
        end

        def getProperty
          # TODO
        end

        def fetch_xml(url:, body:, headers: {}, options: {})
          HTTParty.post(url, body: body, headers: headers)
        end

        def config
          @configuration.to_h
        end

        def api_root
          "https://%{host}/%{webshare}/Webservices" % config
        end

      end
    end
  end
end
