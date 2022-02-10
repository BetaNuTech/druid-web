module Leads
  module Adapters
    class BlueskyPortal
      LEAD_SOURCE_SLUG = 'BlueskyPortal'

      def initialize(params)
        @property_code = get_property_code(params)
        @data = filter_params(params)
      end

      def parse
        return build(data: extract(@data), property_code: @property_code)
      end

      private

      def extract(data)
        {
          first_name: data.fetch('first_name'),
          last_name: data.fetch('last_name'),
          referral: data.fetch('referrer', 'BlueskyPortal'),
          phone1: data.fetch('phone'),
          phone1_type: 'Cell',
          email: data.fetch('email'),
          notes: "Bluesky Portal Lead from #{data.fetch('referrer')}; Creative: #{data.fetch('creative')}; Referrer URL: #{data.fetch('referrer_url')}; Timestamp: #{data.fetch('timestamp')}; Submission: #{data.fetch('submission')}",
          parser: 'BlueskyPortal',
          preference_attributes: {
            baths: data.fetch('bathrooms'),
            beds: data.fetch('bedrooms'),
            pets: data.fetch('pets_allowed'),
            smoker: data.fetch('smoking_allowed'),
            move_in: data.fetch('move_in'),
            optin_sms: data.fetch('sms_allowed'),
            optout_email: !data.fetch('email_allowed'),
            notes: data.fetch('notes'),
          }
        }
      end

      # Return parsed data and meta-information as a Leads::Creator::Result
      def build(data:, property_code:)
        lead = Lead.new(data)
        lead.validate
        status = lead.valid? ? :ok : :invalid
        result = Leads::Creator::Result.new( status: status, lead: data, errors: [], property_code: @property_code)
        return result
      end

      def get_property_code(params)
        return params[:property_id]
      end

      # Filter for whitelisted params
      #
      # (extracted from LeadsController)
      def filter_params(params)
        return params
      end

    end
  end
end
