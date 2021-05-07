require_relative './after55_dot_com_parser'
require_relative './knoxville_apartmentguide_dot_com_parser'
require_relative './apartment_list_dot_com_parser'
require_relative './apartmentguide_dot_com_parser'
require_relative './apartments_dot_com_parser'
require_relative './corporatehousing_dot_com_parser'
require_relative './forrent_dot_com_parser'
require_relative './hotpads_parser'
require_relative './lease_labs_dot_com_parser'
require_relative './rent_dot_com_parser'
require_relative './rentcafe_parser'
require_relative './zillow_parser'
require_relative './null_parser'

module Leads
  module Adapters
    module CloudMailin

      # All Valid CloudMailin Parsers except NullParser
      PARSERS = [
        RentcafeParser,
        CorporatehousingDotComParser, # Goes before all other forrent.com parsers
        KnoxvilleApartmentguideDotComParser,
        LeaseLabsDotComParser,
        After55DotComParser,
        AbodoParser,
        ApartmentguideDotComParser,
        ApartmentListDotComParser,
        ApartmentsDotComParser,
        RentDotComParser,
        HotpadsParser, # Goes before Zillow
        ZillowParser,
        ForrentDotComParser,
        ZumperParser,
      ]

      class Parser
        attr_reader :parser, :data

        def initialize(data)
          @data = data
          @parser = detect_source(@data)
        end

        def parse
          @parser.parse(@data)
        end

        private

        def detect_source(data)
          begin
            PARSERS.detect{|p| p.match?(data)} || NullParser
          rescue => e
            note_message = "CloudMailin Lead Parser Error detecting lead source parser:\n" + e.bcktrace
            Leads::Creator.create_event_note(message: note_message, error: true)
            NullParser
          end
        end

      end
    end
  end
end
