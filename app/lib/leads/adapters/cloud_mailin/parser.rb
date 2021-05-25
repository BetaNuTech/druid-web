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
            note_message = "CloudMailin Lead Parser Error detecting lead source parser:\n" + e.backtrace
            Leads::Creator.create_event_note(message: note_message, error: true)
            NullParser
          end
        end

      end
    end
  end
end
