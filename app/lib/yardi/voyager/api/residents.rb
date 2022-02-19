module Yardi
  module Voyager
    module Api
      class Residents < Base
        STUB_DATA_FILENAME = 'spec/support/test_data/residents.json'

        attr_accessor :stub

        def initialize(conf=nil)
          super
          @configuration = Yardi::Voyager::Api::Configuration.new(resident_settings)
          @stub = api_stub_enabled?
        end

        def resident_settings
          get_env = ->(var) {
            prefix = Yardi::Voyager::Api::Configuration::ENV_PREFIX + '_REQUEST_SERVICE'
            ENV.fetch("#{prefix}_#{var.to_s.upcase}", nil)
          }

          {
            username: get_env.call(:username),
            password: get_env.call(:password),
            servername: get_env.call(:servername),
            host: get_env.call(:host),
            webshare: get_env.call(:webshare),
            database: get_env.call(:database),
            vendorname: get_env.call(:vendorname),
            license: get_env.call(:license)
          }
        end

        def getResidents(propertyid, start_date: nil, end_date: DateTime.current)
          residents = []
          request_options = {
            service: 'ItfServiceRequests',
            method: 'GetResident_Search',
            resource: 'itfServiceRequests.asmx',
            propertyid: propertyid
          }

          begin
            if stub_data?
              api_data = load_stub_data
            else
              response = getData(request_options)
              api_data = response.parsed_response
            end
            residents = Yardi::Voyager::Data::Resident.from_GetResidentSearch(api_data)
          rescue => e
            msg = "#{format_request_id} Yardi::Voyager::Api::Residents.getResidents encountered an error fetching data. #{e}"
            full_msg = "#{msg}"
            puts full_msg
            Rails.logger.error full_msg
            create_event_note(propertyid: propertyid, incoming: true, message: full_msg, error: true)
            return []
          end

          return residents
        end

        def request_template(method=nil)
          case method
          when 'GetResident_Search'
            template_GetResident_Search
          else
            template_GetResident_Search
          end
        end

        def template_GetResident_Search
          body_template = <<~EOS
            <?xml version="1.0" encoding="utf-8"?>
            <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
              <soap:Body>
                <%{method} xmlns="http://tempuri.org/YSI.Interfaces.WebServices/ItfServiceRequests">
									<UserName>%{username}</UserName>
									<Password>%{password}</Password>
									<ServerName>%{servername}</ServerName>
									<Database>%{database}</Database>
									<Platform>%{platform}</Platform>
									<YardiPropertyId>%{propertyid}</YardiPropertyId>
									<InterfaceEntity>%{vendorname}</InterfaceEntity>
									<InterfaceLicense>%{license}</InterfaceLicense>
                  <Address></Address>
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

        def api_stub_enabled?
          ENV.fetch('STUB_RESIDENT_API', false).present?
        end

        def stub_data?
          !Rails.env.production? && @stub
        end

        def load_stub_data
          JSON.parse(File.read(STUB_DATA_FILENAME))
        end
      end
    end
  end
end
