module Leads
  module Adapters
    # Reference passthrough data adapter
    # This class corresponds to a LeadSource record with the slug value 'Druid'
    class Druid
      LEAD_SOURCE_SLUG = 'Druid'

      def initialize(params)
        @data = filter_params(params)
      end

      # Return parsed data and meta-information as a hash.
      # This includes at least the following keys: :status, :lead, :errors
      #
      # Ex: {status: :ok, lead: { .. lead attributes .. }, errors: []}
      #
      # Ex: {status: :error, lead: { .. lead attributes }, errors: ['one', 'two', 'three']}
      def parse
        lead = Lead.new(@data)
        lead.validate
        status = lead.valid? ? :ok : :invalid
        return { status: status, lead: @data, errors: lead.errors }
      end

      private

      # Filter for whitelisted params
      #
      # (extracted from LeadsController)
      def filter_params(params)
        valid_lead_params = Lead::ALLOWED_PARAMS
        valid_preference_params = [{preference_attributes: LeadPreference::ALLOWED_PARAMS }]
        filterable_params = params.is_a?(ActionController::Parameters) ? params : ActionController::Parameters.new(params)
        return filterable_params.permit(*(valid_lead_params + valid_preference_params))
      end

    end
  end
end
