require_relative './rent_dot_com_parser'
require_relative './null_parser'

module Leads
  module Adapters
    module CloudMailin
      PARSERS = [RentDotComParser, ApartmentsDotComParser]

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
          PARSERS.detect{|p| p.match?(data)} || NullParser
        end

      end
    end
  end
end
