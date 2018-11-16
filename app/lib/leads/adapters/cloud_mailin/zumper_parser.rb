module Leads
  module Adapters
    module CloudMailin

      class ZumperParser
        def self.match?(data)
          return data.fetch("headers",{}).fetch("Subject","").
            match(/Zumper/).
            present?
        end

        def self.parse(data)
          body = data.fetch('html','')
          message_id = data.fetch('headers',{}).fetch("Message-ID","").strip
          _, full_name, email = (data.fetch("headers", {}).fetch("Reply-To","").match(/\A([^<]+) <([^>]+)>/).to_a rescue [nil, '', '', ''])
          first_name, last_name = ( full_name || '' ).split
          title = nil
          referral = "Zumper.com"
          phone1 = nil
          phone2 = nil
          fax = nil
          if (beds_baths = (body.match(/The following lead[^:]+[^>]+>[^:]+: ([^<]+)/)[1] rescue '')).empty?
            beds = nil
            baths = nil
          else
            _, beds, baths = ( beds_baths.match(/(\d).+(\d)/).to_a rescue [nil, nil, nil])
            beds = beds.to_i
            baths = baths.to_i
          end
          notes = self.sanitize(( body.match(/padding: 13px">(.*)\s+<\/p>\s+<p st/m)[1] rescue '(None)' ).strip.gsub("\n"," "))
          smoker = nil
          pets = nil
          move_in = nil
          agent_notes = message_id.empty? ? nil : "/// Message-ID: #{message_id}"
          raw_data = data.to_json

          parsed = {
            title: title,
            first_name: first_name,
            last_name: last_name,
            referral: "Zumper.com",
            phone1: phone1,
            phone1_type: nil,
            phone2: phone2,
            phone2_type: nil,
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
