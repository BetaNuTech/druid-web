module Leads
  module Adapters
    module CloudMailin
      class CorporatehousingDotComParser

        class << self
          def match?(data)
            return data.fetch("headers",{}).fetch("From","").
              match?("CorporateHousing").
              present?
          end

          def parse(data)
            format, body = CorporatehousingDotComParser.get_format_and_body(data)
            case format
            when :html
              return parse_html(data.merge({body: body}))
            when :plain
              return parse_plain(data.merge({body: body}))
            else
              raise "Unknown format CorporatehousingDotComParser.parse"
            end
          end

          def parse_html(data)
            body = data[:body]
            html = Nokogiri::HTML(body)
            lines = html.css('td').to_a.map(&:content)


            message_id = data.fetch('headers',{}).fetch('Message-ID','').strip
            title = nil
            name = lines.select{|r| r.match(/Name : /)}.first.split(': ').last.split rescue ['Null', 'Null']
            first_name = name.first.strip
            last_name = name.last.strip
            last_name = nil if last_name == first_name
            referral = "CorporateHousing.com"
            phone1 = lines.select{|r| r.match(/Phone : /)}.first.split(': ').last.strip
            phone2 = nil
            email = lines.select{|r| r.match(/Email : /)}.first.split(': ').last.strip
            notes = lines.select{|r| r.match(/Comments: /)}.first.split('Comments: ').last.strip
            fax = nil
            baths = nil
            beds = nil
            smoker = nil
            pets = nil
            move_in = lines.select{|r| r.match(/Departure Date : /)}.first.split(': ').last.strip
            move_in = DateTime.strptime(move_in, "%m/%d/%y") + 8.hours # Ensure that we don't get the day before due to UTC TZ
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
            # NOT IMPLEMENTED
            raw_data = data.to_json

            parsed = {
              title: nil,
              first_name: nil,
              last_name: nil,
              referral: nil,
              phone1: nil,
              phone1_type: 'Cell',
              phone2: nil,
              phone2_type: 'Cell',
              email: nil,
              fax: nil,
              notes: "/// Message-ID: #{message_id}",
              preference_attributes: {
                baths: nil,
                beds: nil,
                notes: nil,
                smoker: nil,
                raw_data: nil,
                pets: nil,
                move_in: nil
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
