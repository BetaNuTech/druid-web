module Leads
  module Adapters
    module CloudMailin
      class ZillowParser
        def self.match?(data)
          return (data.fetch(:headers, {}).fetch('Subject',"")).
            match?("Zillow Group").
            present?
        end

        def self.parse(data)
          # TODO
          #  * beds
          #  * baths
          body = data.fetch(:plain,nil) || data.fetch(:html,nil) || ''

          name = ( body.match(/New Contact(.+) says:/m)[1] rescue '(Parse Error)' ).gsub('*','')
          name_arr = name.split(' ')

          message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
          title = nil
          first_name = ( name_arr.first.chomp rescue nil )
          last_name = ( name_arr.last.chomp rescue nil )
          last_name = nil if last_name == first_name
          referral = "Zillow.com"
          phone1 = (body.match(/([0-9]{3}[-.][0-9]{3}[-.][0-9]{3})/)[1] rescue '(Parse Error)')
          phone2 = nil
          email = ( body.match(/<([^\?]+)\?subject=/m)[1] rescue '(Parse Error)' ).strip
          fax = nil
          baths = nil
          beds = nil
          notes = ( body.match(/says[^"]+"(.+)".</m)[1] rescue '(Parse Error)' ).strip.gsub("\n"," ")
          smoker = nil
          pets = nil
          move_in = nil
          raw_data = ''

          parsed = {
            title: title,
            first_name: first_name,
            last_name: last_name,
            referral: referral,
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
