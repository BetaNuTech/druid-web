module Leads
  module Adapters
    module CloudMailin
      class ApartmentListDotComParser
        def self.match?(data)
          return data.fetch(:envelope, {}).fetch(:from, '').
                  match?(/apartmentlist.com/).
                  present?
        end

        def self.parse(data)
          Date::DATE_FORMATS[:default] = "%m/%d/%Y"
          # TODO
          #  * beds
          #  * baths
          body = data.fetch(:plain,nil) || data.fetch(:html,nil) || ''

          name = (body.match(/ +(.+) is (looking at|interested in)/i)[1] rescue '(None)' )
          name_arr = name.split(' ')

          message_id = data.fetch(:headers,{}).fetch("Message-ID","").strip
          title = nil
          first_name = ( name_arr.first.chomp rescue nil )
          last_name = ( name_arr.last.chomp rescue nil )
          referral = "ApartmentList.com"
          phone1 = (body.match(/PHONE: (.+)$/)[1] rescue '(None)' ).strip
          phone2 = nil
          email = (body.match(/EMAIL: (.+)$/)[1] rescue '(None)' ).strip
          fax = nil
          baths = nil
          beds = (body.match(/BEDS: (\d)/)[1] rescue nil)
          notes = self.sanitize(( body.match(/\*preference\*(.+)Apartment List/m)[1] rescue '(None)' ).strip.gsub("\n"," "))
          smoker = nil
          pets = (body.match(/PETS:/)).present?
          move_in = (body.match(/MOVE-IN: ([^ ]+) /)[1] rescue nil)
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
