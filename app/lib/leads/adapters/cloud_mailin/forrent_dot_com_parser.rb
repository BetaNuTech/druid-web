module Leads
  module Adapters
    module CloudMailin

      class ForrentDotComParser
        def self.match?(data)
          return (data.fetch(:plain, nil) || data.fetch(:html,nil) || '').
            match('FORRENT.COM GUESTCARD').
            present?
        end

        def self.parse(data)
          body = data.fetch(:plain,nil) || data.fetch(:html,nil) || ''

          name = ( body.match(/\[Prospect Name\] (.+)$/)[1] rescue '(None)' ).gsub('*','')
          name_arr = name.split(' ')

          message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
          title = nil
          first_name = ( name_arr.first.chomp rescue nil )
          last_name = ( name_arr.last.chomp rescue nil )
          referral = "ForRent.com"
          phone1 = ( body.match(/\[Phone\] (.+)$/)[1] rescue '(None)' ).strip
          phone2 = nil
          email = ( body.match(/\[Email\] (.+)$/)[1] rescue '(None)' ).strip
          fax = nil
          baths = ( body.match(/\[# Baths\] (.+)$/)[1] rescue '(None)' ).strip.to_f
          beds = ( body.match(/\[# Beds\] (.+)$/)[1] rescue '(None)' ).strip.to_i
          notes = self.sanitize(( body.match(/\[Comments\](.+?)\[Submitted\]/m)[1] rescue '(None)' ).strip.gsub("\n"," "))
          smoker = nil
          pets = nil
          move_in = ( body.match(/\[Moving Date\] (.+)/)[1] rescue '(None)' ).strip.gsub("\n"," ")
          move_in = (DateTime.strptime(move_in, "%m/%d/%Y") rescue nil)
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
