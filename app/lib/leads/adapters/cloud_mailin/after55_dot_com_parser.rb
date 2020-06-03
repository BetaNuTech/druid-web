module Leads
  module Adapters
    module CloudMailin

      class After55DotComParser
        def self.match?(data)
          return (data.fetch("headers",{}).fetch('From','').
                  match?('After55')
                 )
        end

        def self.parse(data)
          body = data.fetch(:plain,nil) || data.fetch(:html,nil) || ''

          first_name = ( body.match(/First Name: (\w+)/)[1] rescue '(None)').strip
          last_name = ( body.match(/Last Name: (\w+)/)[1] rescue '(None)').strip

          message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
          title = nil
          referral = "After55.com"
          phone1 = (body.match(/Phone: (.+)/)[1] rescue '(None)').strip
          phone2 = nil
          email = (body.match(/Email: (.+)/)[1] rescue '(None)').strip
          fax = nil
          baths = nil
          beds = nil
          notes = nil
          smoker = nil
          pets = nil
          move_in = (body.match(/Move-In Date: (.+)/)[1] rescue '(None)').strip
          move_in = (DateTime.strptime(move_in, "%m/%d/%Y") rescue nil)
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
