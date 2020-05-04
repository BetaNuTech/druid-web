module Leads
  module Adapters
    module CloudMailin
      class LeaseLabsDotComParser

        class << self
          def match?(data)
            return (data.fetch(:headers, {}).fetch('From',"")).
              match?('leaselabs.com').
              present?
          end

          def parse(data)
            format, body = LeaseLabsDotComParser.get_format_and_body(data)
            case format
            when :html
              return parse_html(data.merge({body: body}))
            when :plain
              return parse_plain(data.merge({body: body}))
            else
              raise "Unknown format LeaseLabsDotComParser.parse"
            end
          end

          def parse_html(data)
            body = data[:body]
            html = Nokogiri::HTML(body)
            container = html.css('table')

            raw_name = container.css('tr:nth-child(2) td:nth-child(2)').text
            name = raw_name.split(' ')

            message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
            title = nil
            first_name = name.first
            last_name = name.last
            last_name = nil if last_name == first_name
            referral = "LeaseLabs.com"
            phone1 = container.css('tr:nth-child(4) td:nth-child(2)').text
            phone2 = nil
            email = container.css('tr:nth-child(3) td:nth-child(2)').text
            fax = nil
            baths = nil
            beds = nil
            notes = nil
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
            return {}
            ## TODO
            ##  * beds
            ##  * baths
            #body = data[:body]

            #name = ( body.match(/New Contact(.+) says:/m)[1] rescue '(None)' ).gsub('*','')
            #name_arr = ( name || '' ).split(' ')

            #message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
            #title = nil
            #first_name = ( name_arr.first.chomp rescue nil )
            #last_name = ( name_arr.last.chomp rescue nil )
            #last_name = nil if last_name == first_name
            #referral = "Zillow.com"
            #phone1 = (body.match(/([0-9]{3}[-.][0-9]{3}[-.][0-9]{3})/)[1] rescue '(None)')
            #phone2 = nil
            #email = ( body.match(/<([^\?]+)\?subject=/m)[1] rescue '(None)' ).strip
            #fax = nil
            #baths = nil
            #beds = nil
            #notes = self.sanitize(( body.match(/says[^"]+"(.+)".</m)[1] rescue '(None)' ).strip.gsub("\n"," "))
            #smoker = nil
            #pets = nil
            #move_in = nil
            #agent_notes = message_id.empty? ? nil : "/// Message-ID: #{message_id}"
            #raw_data = data.to_json

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
              #notes: "/// Message-ID: #{message_id}",
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
