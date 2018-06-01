module Messages
  module DeliveryAdapters
    module Twilioadapter

      # All Valid Twilio Parsers except NullParser
      PARSERS = [
        SmsParser
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
          PARSERS.detect{|p| p.match?(data)} || NullParser
        end

      end
    end
  end
end
