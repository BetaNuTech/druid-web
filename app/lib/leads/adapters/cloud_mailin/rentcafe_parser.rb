module Leads
  module Adapters
    module CloudMailin
      class RentcafeParser
        def self.match?(data)
          sender_matches = data&.fetch('headers',{})&.fetch('From','')&.match(/rentcafe\.com/).present?
          body_text = data.fetch('html','')
          body_matches = body_text.match('The following prospect has requested information about your property').present? ||
                         body_text.match('The following prospect has set up an availability alert').present?
          return(sender_matches && body_matches)
        end

        def self.parse(data)
          format, body = RentcafeParser.get_format_and_body(data)
          case format
          when :html
            return parse_html(data.merge({body: body}))
          when :plain
            return parse_plain(data.merge({body: body}))
          else
            raise "Unknown format RentcafeParser.parse"
          end
        end

        def self.sanitize(value)
          return ActionController::Base.helpers.sanitize(value)
        end

        def self.get_format_and_body(data)
          if data.is_a?(ActionController::Parameters)
            d = data
          else
            d = data.symbolize_keys
          end

          plain_body = d.fetch(:plain, nil)
          html_body = d.fetch(:html, nil)

          if ( plain_body || '' ).empty?
            if ( html_body || '' ).empty?
              return [:err, '']
            else
              return [ :html, html_body ]
            end
          else
            return [ :plain, plain_body ]
          end
        end

        def self.parse_plain(data)
          return {}
        end

        def self.parse_html(data)
          body = data[:body]
          html = Nokogiri::HTML(body)
          container = html.css('table')

          referral = "Property Website"
          message_id = data.fetch('headers',{}).fetch("Message-ID","").strip
          raw_name = container.css('div.normaltext span[data-selenium-id="ProspectName"]')&.text
          name = raw_name.split(' ')
          first_name = name.first
          last_name = name.last
          last_name = nil if last_name == first_name
          phone1 = container.css('div.normaltext span[data-selenium-id="ProspectPhone"]')&.text
          phone2 = container.css('div.normaltext span[data-selenium-id="ProspectAltPhone"]')&.text
          email = container.css('div.normaltext span[data-selenium-id="ProspectEmail"]')&.text
          notes = container.css('div.normaltext span[data-selenium-id="ProspectComments"]')&.text
          remoteid = ( container.css('div.normaltext span[data-selenium-id="ProspectMatch"]')&.text&.match(/Voyager Code: (.+)/)[1] rescue nil )
          title = nil
          baths = nil
          beds = nil
          fax = nil
          move_in = nil
          pets = nil
          smoker = nil
          raw_data = data.to_json

          parsed = {
            title: title,
            first_name: first_name,
            last_name: last_name,
            referral: referral,
            phone1: phone1,
            phone1_type: 'Cell',
            phone2: phone2,
            phone2_type: 'Cell',
            email: email,
            fax: fax,
            notes: nil,
            remoteid: remoteid,
            preference_attributes: {
              baths: baths,
              beds: beds,
              notes: notes,
              smoker: smoker,
              raw_data: raw_data,
              pets: pets,
              move_in: move_in
            }
          }

          return parsed
        end
      end
    end
  end
end
