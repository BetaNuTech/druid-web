module Leads
  module Adapters
    module CloudMailin
      class HotpadsParser
        # This parser should be declared/loaded before Zillow
        class << self
          def match?(data)
            format, body = get_format_and_body(data)
            return body.match?("hotpads.com").present?
          end

          def parse(data)
            format, body = HotpadsParser.get_format_and_body(data)
            case format
            when :html
              return parse_html(data.merge({body: body}))
            when :plain
              return parse_plain(data.merge({body: body}))
            else
              raise "Unknown format in HotpadsParser.parse"
            end
          end

          def parse_html(data)
            body = data[:body]
            html = Nokogiri::HTML(body)
            container = html.css('td.h-card')

            raw_name_and_unit = container.css('span.p-name').text
            interest, raw_name, raw_unit = raw_name_and_unit.match(/(.+) is interested in (.+) and says/).to_a
            name = raw_name.split(' ')

            message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
            title = nil
            first_name = name.first
            last_name = name.last
            last_name = nil if last_name == first_name
            referral = "HotPads.com"
            phone1 = container.css('td.phone-button-wrapper td.btn-text font.p-tel').text
            phone2 = nil
            email = container.css('table.email-button-tbl td.btn-text a font.p-email').text
            fax = nil
            baths = nil
            beds = nil
            notes = interest + ": " + (container.css('tr:nth-child(2) td').text || '').strip.gsub('"','')
            smoker = nil
            pets = nil
            move_in = nil
            agent_notes = nil
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

          def parse_plain(data)
            # TODO ?
            message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
            title = nil
            first_name = '(None)'
            last_name = name.last
            last_name = nil if last_name == first_name
            referral = "HotPads.com"
            phone1 = nil
            phone2 = nil
            email = '(None)'
            fax = nil
            baths = nil
            beds = nil
            notes = 'Unexepected email format'
            smoker = nil
            pets = nil
            move_in = nil
            agent_notes = nil
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
              notes: "/// Message-ID: #{message_id}",
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

          def get_format_and_body(data)
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

          def sanitize(value)
            return ActionController::Base.helpers.sanitize(value)
          end

        end
      end
    end
  end
end
