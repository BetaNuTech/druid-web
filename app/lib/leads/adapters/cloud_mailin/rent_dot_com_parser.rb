module Leads
  module Adapters
    module CloudMailin

      class RentDotComParser
        def self.match?(data)
          return (data.fetch(:envelope,{}).fetch(:from,'')).
            match?(/(?<!for)rent.com/) ||
          (data.fetch('headers',{}).fetch('From','')).
            match?(/(?<!for)rent.com/)
        end

        def self.parse(data)
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
