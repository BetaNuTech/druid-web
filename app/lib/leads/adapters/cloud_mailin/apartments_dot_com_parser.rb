module Leads
  module Adapters
    module CloudMailin
      class ApartmentsDotComParser
        def self.match?(data)
          return (data.fetch(:envelope,{}).fetch(:from, "")).
            match("lead@apartments.com")
        end

        def self.parse(data)
          # TODO
          #  * beds
          #  * baths
          body = data.fetch(:html,nil) || ''

          name = ( body.match(/Name: ([\w ]+)/m)[1] rescue '(Parse Error)' ).strip
          name_arr = name.split(' ')

          message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
          title = nil
          first_name = ( name_arr.first.chomp rescue nil )
          last_name = ( name_arr.last.chomp rescue nil )
          referral = "Apartments.com"
          phone1 = nil
          phone2 = nil
          #email = ( body.match(/Email: (.+)$/)[1] rescue '(Parse Error)' ).strip
          email = (data.fetch(:headers,{}).fetch("Reply-To",""))
          fax = nil
          baths = nil
          beds = nil
          notes = ( body.match(/Comments: (.+)Property Information/m)[1] rescue '(Parse Error)' ).strip.gsub("\n"," ")
          smoker = nil
          pets = nil
          move_in = ( (body.match(/Move Date: (.*)$/)[1]) rescue nil )
          move_in = (DateTime.strptime(move_in, "%m/%d/%Y") rescue nil)
          raw_data = ''

          parsed = {
            title: title,
            first_name: first_name,
            last_name: last_name,
            referral: "Apartments.com",
            phone1: phone1,
            phone2: phone2,
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
      end
    end
  end
end
