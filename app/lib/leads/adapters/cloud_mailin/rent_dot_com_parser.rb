module Leads
  module Adapters
    module CloudMailin

      class RentDotComParser
        def self.match?(data)
          data = data.with_indifferent_access
          return (data.fetch(:envelope,{}).fetch(:from,'')).
            match?(/(?<!for)rent.com/) ||
          (data.fetch('headers',{}).fetch('From','')).
            match?(/(?<!for)rent.com/)||
          (data.fetch('headers',{}).fetch('Reply-To','')).
            match?(/(?<!for)rent.com/)
        end

        def self.parse(data)
          data = data.with_indifferent_access

          if data.fetch(:plain,'').match?(/First Name/)
            return self.parse_text_v1(data)
          end

          if (data.fetch(:html,'').match?(/checked you guys out/) rescue false )
            return self.parse_html_v2(data)
          else
            return self.parse_html_v1(data)
          end

        end

        def self.parse_text_v1(data)
          referral = "Rent.com"
          message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
          agent_notes = message_id.empty? ? nil : "/// Message-ID: #{message_id}"

          text_body = data.fetch(:plain,'')
          first_name = ( text_body.match(/First Name: (.*)$/)[1] rescue '').strip
          last_name = ( text_body.match(/Last Name: (.*)$/)[1] rescue '').strip
          phone1 = ( text_body.match(/Phone: (.*)$/)[1] rescue '').strip
          email = ( text_body.match(/Email: (.*)$/)[1] rescue '').strip
          notes = ( text_body.match(/Message: (.*)$/)[1] rescue '').strip
          move_in = ( text_body.match(/Move In Date: (.*)$/)[1] rescue '').strip

          title = nil
          phone2 = nil
          fax = nil
          baths = nil
          beds = nil
          smoker = nil
          pets = nil

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
            notes: agent_notes,
            preference_attributes: {
              baths: baths,
              beds: beds,
              notes: notes,
              smoker: smoker,
              raw_data: data.to_json,
              pets: pets,
              move_in: move_in
            }
          }

          return parsed
        end


        def self.parse_html_v2(data)
          body = data.fetch(:html,'')
          html = Nokogiri::HTML(body)

          container = html.css('table')

          referral = "Rent.com"
          message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip

          raw_name = container.css('tr:nth-child(6) strong').text
          name_arr = raw_name.split(' ')
          if name_arr.length > 2
            first_name = ( name_arr[0..1].amp(&:chomp).join(' ') rescue '' )
          else
            first_name = ( name_arr.first.chomp rescue '' )
          end
          last_name = ( name_arr.last.chomp rescue '' )

          email_raw = container.css('tr:nth-child(7)').text
          email = (email_raw.match(/Email:.([^\n\t ]+)/)[1] rescue '(None)').strip

          phone_raw = container.css('tr:nth-child(8)').text
          phone1 = (phone_raw.match(/Phone:.([^\n\t]+)/)[1] rescue '(None)').strip

          move_in_raw = container.css('tr:nth-child(10)').text
          move_in = (move_in_raw.match(/Move Date:.([^\n\t]+)/)[1] rescue nil).strip

          notes_raw = container.css('tr:nth-child(11)').text
          notes = (notes_raw.match(/Comments:.([^\n\t]+)/)[1] rescue '(None)').strip.gsub("\n"," ")

          agent_notes = message_id.empty? ? nil : "/// Message-ID: #{message_id}"

          title = nil
          phone2 = nil
          fax = nil
          baths = nil
          beds = nil
          smoker = nil
          pets = nil

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
            notes: agent_notes,
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

        def self.parse_html_v1(data)
          body = data.fetch(:html,'')

          name = ( body.match(/Information for.+?<strong>(.+?)<\/strong>/)[1] rescue '(None)' ).gsub('*','')
          name_arr = name.split(' ')

          message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
          title = nil
          first_name = ( name_arr.first.chomp rescue '' )
          last_name = ( name_arr.last.chomp rescue '' )
          referral = "Rent.com"
          phone1 = ( body.match(/Phone.+?<\/span>.+?>([^<]+)<\/a>/)[1] rescue '(None)' ).strip
          phone2 = nil
          email = ( body.match(/Email.+?<\/span>.+?>([^<]+)<\/a>/)[1] rescue '(None)' ).strip
          fax = nil
          baths = nil
          beds = nil
          notes = self.sanitize(( body.match(/Comments.+?<\/span>(.+?)<\/td>/m)[1] rescue '(None)' ).strip.gsub("\n"," "))
          smoker = nil
          pets = nil
          move_in = (Date.parse(body.match(/Move Date.+?<\/span>(.*?)<\/td>/m)[1]) rescue nil)
          agent_notes = message_id.empty? ? nil : "/// Message-ID: #{message_id}"

          raw_data = data.to_json

          parsed = {
            title: title,
            first_name: first_name,
            last_name: last_name,
            referral: "Rent.com",
            phone1: phone1,
            phone1_type: 'Cell',
            phone2: phone2,
            phone2_type: 'Cell',
            email: email,
            fax: fax,
            notes: agent_notes,
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

        def self.sanitize(value)
          return ActionController::Base.helpers.sanitize(value)
        end
      end
    end
  end
end
