module Leads
  module Adapters
    module CloudMailin
      class LoopnetParser
        DOMAIN = 'loopnet.com'
        REFERRAL = 'LoopNet'

        class << self
          def match?(data)
            return (data.fetch('headers', {}).fetch('X-Original-From',"")).
              match?(DOMAIN).
              present?
          end

          def parse(data)
            format, body = self.get_format_and_body(data)
            case format
            when :html
              return parse_html(data.merge({body: body}))
            when :plain
              return parse_plain(data.merge({body: body}))
            else
              raise "Unknown format #{self.classname}.parse"
            end
          end

          def parse_html(data)
            body = data[:body]
            html = Nokogiri::HTML(body)

            referral = REFERRAL
            message_id = data.fetch('headers',{}).fetch('Message-ID',"").strip
            raw_data = data.to_json

            lead_data = html.css("table tr .modList").first.text.
                          match(/From: (.+)/)[0].
                          split('|').map(&:strip)
            names = lead_data[0].split('From: ').last.split(' ')

            first_name, last_name = [names[0..([0,( names.length - 2 ) ].max)].join(' '), names[-1]]
            last_name = nil if last_name == first_name
            title = nil
            phone1 = lead_data[1]
            phone2 = nil
            email = lead_data[2]
            fax = nil
            baths = nil
            beds = nil
            notes = nil
            smoker = nil
            pets = nil
            move_in = nil
            agent_notes = nil

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
            # TODO
            #body = data[:body]

            #referral = REFERRAL
            #raw_data = data.to_json
            #message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
            #title = nil
            #first_name = nil
            #last_name = nil
            #last_name = nil if last_name == first_name
            #phone1 = nil
            #phone2 = nil
            #email = nil
            #fax = nil
            #baths = nil
            #beds = nil
            #notes = nil
            #smoker = nil
            #pets = nil
            #move_in = nil
            #agent_notes = nil

            #parsed = {
              #title: title,
              #first_name: first_name,
              #last_name: last_name,
              #referral: referral,
              #phone1: phone1,
              #phone1_type: 'Cell',
              #phone2: phone2,
              #phone2_type: 'Cell',
              #email: email,
              #fax: fax,
              #notes: nil,
              #preference_attributes: {
                #baths: baths,
                #beds: beds,
                #notes: notes,
                #smoker: smoker,
                #raw_data: raw_data,
                #pets: pets,
                #move_in: move_in
              #}
            #}

            #return parsed
            {}
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
