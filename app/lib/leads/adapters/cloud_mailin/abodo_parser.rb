module Leads
  module Adapters
    module CloudMailin
      class AbodoParser

        def self.match?(data)
          return (data.fetch(:plain, nil) || data.fetch(:html,nil) || '').
            match('ABODO').
            present?
        end

        def self.parse(data)
          Date::DATE_FORMATS[:default] = "%m/%d/%Y"
          body = data.fetch("plain",nil) || ''

          referral = 'Rentable.com'
          message_id = data.fetch("headers",{}).fetch("Message-ID","").strip
          agent_notes = message_id.empty? ? nil : "/// Message-ID: #{message_id}"

          name = ( body.match(/Name: (.+)Email/m)[1] rescue '(None)' ).gsub('*','').strip
          name_arr = name.split(' ')
          first_name = ( name_arr.first.chomp rescue nil )
          last_name = ( name_arr.last.chomp rescue nil )

          phone1 = ( body.match(/Phone Number: (.*)Student/m)[1] rescue '(None)' ).strip
          email = ( body.match(/Email: (.+)Phone Number/m)[1] rescue '(None)' ).strip
          notes = (( body.match(/Property:[^\n]+(.+)View Additional/m))[1] rescue '(None)').strip
          raw_data = data.to_json

          phone2 = nil
          baths = nil
          beds = nil
          fax = nil
          move_in = nil
          pets = nil
          smoker = nil
          title = nil

          parsed = {
            title: nil,
            first_name: first_name,
            last_name: last_name,
            referral: referral,
            phone1: phone1,
            phone1_type: 'Cell',
            phone2: nil,
            phone2_type: nil,
            email: email,
            fax: nil,
            notes: agent_notes,
            preference_attributes: {
              baths: nil,
              beds: nil,
              notes: notes,
              smoker: nil,
              raw_data: raw_data,
              pets: nil,
              move_in: nil
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
