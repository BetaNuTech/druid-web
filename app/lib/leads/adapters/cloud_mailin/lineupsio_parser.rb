module Leads
  module Adapters
    module CloudMailin
      class LineupsioParser
        REFERRAL="Lineups.io"

        def self.match?(data)
          sender_matches = data&.fetch('headers',{})&.fetch('From','')&.match(/lineups.io/i).present?
          body_text = data.fetch('text', data.fetch('html',''))
          body_matches = body_text.match(/lineups.io/i).present?
          return(sender_matches || body_matches)
        end

        def self.parse(data)
          body = data.fetch(:html)
          return parse_html(data.merge({body: body}))
        end

        def self.sanitize(value)
          return ActionController::Base.helpers.sanitize(value)
        end

        def self.parse_html(data)
          first_name = 'Error'
          last_name = 'Error'
          phone1 = nil
          email = nil
          notes = nil
          move_in = nil
          beds = nil

          begin
            body = data[:body]
            doc = Nokogiri::XML(body)

            referral = REFERRAL
            message_id = data.fetch('headers',{}).fetch("Message-ID","").strip

            lead_data = doc.xpath('//comment()[contains(.,\'PROSPECT\')]').inner_text.sub(/PROSPECT = /i,'')
            lead_data = JSON.parse(lead_data)

            first_name = lead_data['first_name']
            last_name = lead_data['last_name']
            phone1 = lead_data['cell_phone']
            email = lead_data['email']
            notes = lead_data['comments']
            move_in = lead_data['desired_move_in']
            beds = lead_data['desired_bedrooms']
          end

          remoteid = nil
          title = nil
          baths = nil
          phone2 = nil
          fax = nil
          pets = nil
          smoker = nil
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
            notes: nil,
            remoteid: remoteid,
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
