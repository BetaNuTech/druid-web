module Leads
  module Adapters
    module CloudMailin
      class KnoxvilleApartmentguideDotComParser

        def self.match?(data)
          return data.fetch("headers",{}).fetch("Subject",'').
            match?("Knoxville Apartment Guide").
            present?
        end

        def self.parse(data)
          body = data.fetch("plain","")

          name = ""
          name = body.match(/^Name: (.+)$/)[1]
          name_arr = name.split(' ')

          message_id = data.fetch("headers",{}).fetch("Message-ID","").strip
          title = nil
          first_name = ( name_arr.first.chomp rescue nil )
          last_name = ( name_arr.last.chomp rescue nil )
          referral = "KnoxvilleApartmentGuide.com"
          phone1 = (body.match(/^Phone: (.+)$/)[1] rescue '(None)')
          phone2 = nil
          email = (body.match(/^Email: (.+)$/)[1] rescue '(None)')
          fax = nil
          baths = nil
          beds = nil
          notes = nil
          notes_move_in = ( body.match(/^Move-in Date: (.+)$/)[0] rescue '')
          notes = notes_move_in + " -- " + (body.match(/^Message: (.+)/m)[1] rescue '(None)').strip.gsub(/[\r\n]+/,' ')
          smoker = nil
          pets = nil
          move_in = nil
          agent_notes = message_id.empty? ? nil : "/// Message-ID: #{message_id}"
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

        def self.sanitize(value)
          return ActionController::Base.helpers.sanitize(value)
        end

      end
    end
  end
end
