module Leads
  module Adapters
    module CloudMailin
      class ApartmentguideDotComParser

        def self.match?(data)
          return data.fetch("envelope",{}).fetch("from").
            match?(/apartmentguide.com$/).
            present?
        end

        def self.parse(data)
          body = data.fetch("html","")

          name = ""
          name = ( body.match(/Information for.+<strong>([^\<]+)<\/strong>/m)[1] rescue '(None)')
          name_arr = name.split(' ')

          message_id = data.fetch("headers",{}).fetch("Message-ID","").strip
          title = nil
          first_name = ( name_arr.first.chomp rescue nil )
          last_name = ( name_arr.last.chomp rescue nil )
          referral = "ApartmentGuide.com"
          phone1 = ( body.match(/Phone.+?<\/span>.+?tel:([^"]+)/)[1] rescue '(None)')
          phone2 = nil
          email = (body.match(/mailto:([^"]+)/)[1] rescue '(None)')
          fax = nil
          baths = nil
          beds = nil
          notes = nil
          notes = ( body.match(/Comments:.+?span>(.+?)<\/td>/m)[1] rescue '(None)' ).strip.gsub(/[\r\n]+/,' ')
          smoker = nil
          pets = nil
          move_in = ( body.match(/Move Date.+?span>(.+?)<\/td>/m)[1] rescue '(None)' ).strip
          move_in = ( Date.parse(move_in) rescue nil )
          agent_notes = message_id.empty? ? nil : "/// Message-ID: #{message_id}"
          raw_data = data.to_json

          parsed = {
            title: title,
            first_name: first_name,
            last_name: last_name,
            referral: referral,
            phone1: phone1,
            phone2: phone2,
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
