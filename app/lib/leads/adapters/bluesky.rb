module Leads
  module Adapters
    # Reference passthrough data adapter
    # This class corresponds to a LeadSource record with the slug value 'Bluesky'
    class Bluesky
      LEAD_SOURCE_SLUG = 'Bluesky'

      def initialize(params)
        @property_code = get_property_code(params)
        @data = filter_params(params)
      end

      # Return parsed data and meta-information as a Leads::Creator::Result
      def parse
        lead = Lead.new(@data)
        lead.validate
        status = lead.valid? ? :ok : :invalid
        result = Leads::Creator::Result.new( status: status, lead: @data, errors: lead.errors, property_code: @property_code)
        return result
      end

      private

      def get_property_code(params)
        return params[:property_id]
      end

      # Filter for whitelisted params
      #
      # (extracted from LeadsController)
      def filter_params(params)
        valid_lead_params = Lead::ALLOWED_PARAMS - Lead::PRIVILEGED_PARAMS + [:property_id]
        valid_preference_params = [{preference_attributes: LeadPreference::ALLOWED_PARAMS - LeadPreference::PRIVILEGED_PARAMS }]
        filterable_params = params.is_a?(ActionController::Parameters) ? params : ActionController::Parameters.new(params)
        return filterable_params.permit(*(valid_lead_params + valid_preference_params))
      end

    end
  end
end
