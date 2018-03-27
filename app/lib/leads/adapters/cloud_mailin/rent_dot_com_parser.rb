module Leads
  module Adapters
    module CloudMailin

      class RentDotComParser
        def self.match?(data)
          return (data.fetch(:envelope,{}).fetch(:from,"")).
            match("rent.com")
        end

        def self.parse(data)
          body = data.fetch(:plain,nil) || data.fetch(:html,nil) || ''

          name = ( body.match(/Information for (.+)$/)[1] rescue '(Parse Error)' ).gsub('*','')
          name_arr = name.split(' ')

          message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
          title = nil
          first_name = ( name_arr.first.chomp rescue nil )
          last_name = ( name_arr.last.chomp rescue nil )
          referral = "Rent.com"
          phone1 = nil
          phone2 = nil
          email = ( body.match(/Email: (.+)$/)[1] rescue '(Parse Error)' ).strip
          fax = nil
          baths = nil
          beds = nil
          notes = ( body.match(/Comments: (.+)Property Information/m)[1] rescue '(Parse Error)' ).strip.gsub("\n"," ")
          smoker = nil
          raw_data = ''
          pets = nil
          move_in = (Date.parse(body.match(/Move Date: (.*)$/)[1]) rescue nil)

          parsed = {
            title: title,
            first_name: first_name,
            last_name: last_name,
            referral: "Rent.com",
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
