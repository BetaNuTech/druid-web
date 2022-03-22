module Leads
  module Adapters
    module CloudMailin
      class ApartmentsDotComParser
        def self.match?(data)
          sender_addresses = []
          sender_addresses << data.fetch(:envelope,{}).fetch(:from, '')
          sender_addresses << data.fetch('headers',{}).fetch('X-Original-From', '')

          return sender_addresses.any?{|a| a.match("lead@apartments.com")}
        end

        def self.parse(data)
          # TODO
          #  * beds
          #  * baths
          body = data.fetch(:html,nil) || ''

          name = ( body.match(/Name: ([\w ]+)/m)[1] rescue '(None)' ).strip
          name_arr = name.split(' ')

          message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
          title = nil
          first_name = ( name_arr.first.chomp rescue nil )
          last_name = ( name_arr.last.chomp rescue nil )
          referral = "Apartments.com"
          phone1 = (body.match(/PHONE: (.+)$/i)[1] rescue '(None)' ).strip
          phone1 = nil if (phone1 ||'').gsub(/[^\d]/,'').length < 10
          phone2 = nil
          #email = ( body.match(/Email: (.+)$/)[1] rescue '(None)' ).strip
          email = (data.fetch(:headers,{}).fetch("Reply-To",""))
          fax = nil
          beds_baths = (body.match(/Beds\/Baths: (\d)\/?(\d?)/i) rescue [nil,nil,nil])
          beds = beds_baths[1] rescue nil
          baths = beds_baths[2] rescue nil
          notes = self.sanitize(( body.match(/Comments:(.+?)<br/m)[1] rescue '(None)' ).gsub("\n"," ")).strip
          smoker = nil
          pets = nil
          move_in = ( (body.match(/Move Date: (.*)$/)[1]) rescue nil )
          move_in = (DateTime.strptime(move_in, "%m/%d/%Y") rescue nil)
          agent_notes = message_id.empty? ? nil : "/// Message-ID: #{message_id}"
          raw_data = data.to_json

          parsed = {
            title: title,
            first_name: first_name,
            last_name: last_name,
            referral: "Apartments.com",
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
