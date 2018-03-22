module Leads
  module Adapters
    module CloudMailin
      class NullParser

        def self.match?(data)
          true
        end

        def self.parse(data)
          return {
            title: 'Null',
            first_name: 'Null',
            last_name: 'Null',
            referral: 'Null',
            phone1: 'Null',
            phone2: 'Null',
            email: 'Null',
            fax: 'Null',
            preference_attributes: {
              baths: 'Null',
              beds: 'Null',
              notes: 'Null',
              smoker: false,
              raw_data: data.to_json,
              pets: false,
              move_in: nil
            }
          }
        end
      end
    end
  end
end
