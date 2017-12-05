module Leads
  module Adapters
    # Reference passthrough data adapter
    # This class corresponds to a LeadSource record with the slug value 'Druid'
    class Druid
      LEAD_SOURCE_SLUG = 'Druid'

      def initialize(params)
        @data = params
      end
    
      # Return parsed data and meta-information as a hash.
      # This includes at least the following keys: :status, :lead, :errors
      #
      # Ex: {status: :ok, lead: { .. lead attributes .. }, errors: []}
      #
      # Ex: {status: :error, lead: { .. lead attributes }, errors: ['one', 'two', 'three']}
      def parse
        return { status: :ok, lead: @data, errors: [] }
      end
    end
  end
end
