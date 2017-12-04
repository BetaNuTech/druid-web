module Leads
  module Adapters
    class Druid
      def initialize(params)
        @data = params
      end

      def parse
        return @data
      end
    end
  end
end
