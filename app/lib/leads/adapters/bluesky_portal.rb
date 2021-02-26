module Leads
  module Adapters
    class BlueskyPortal
      require 'twilio-ruby'

      LEAD_SOURCE_SLUG = 'BlueskyPortal'

      # Used Twilio API to fetch CallerID information
      # CHARGES APPLY!
      def self.get_callerid(phone)
        phone_number = PhoneNumber.format_phone(phone, prefixed: true)
        twilio_account_sid = ENV.fetch('MESSAGE_DELIVERY_TWILIO_SID', '')
        twilio_auth_token = ENV.fetch('MESSAGE_DELIVERY_TWILIO_TOKEN', '')
        service = Twilio::REST::Client.new(twilio_account_sid, twilio_auth_token)
        number_data = service.lookups.v1.phone_numbers(phone_number).fetch(type: 'caller-name')
        msg = "Twilio API called to lookup phone number in Leads::Adapters::BlueskyPortal.get_callerid: #{phone_number}"
        Rails.logger.warn(msg)
        Note.create(content: msg, classification: :external)
        Rails.logger.debug number_data
        number_data.caller_name.fetch('caller_name')
      rescue => e
        Rails.logger.error('Error fetching Blueconnect Caller ID: ' + e.to_s)
        'Unknown'
      end

      def initialize(params)
        @property_code = get_property_code(params)
        @data = filter_params(params)
        @lookup_service = init_lookup_service
      end

      def parse
        return build(data: extract(@data), property_code: @property_code)
      end

      private

      def extract(data)
        caller_name = get_callerid(data.fetch('phone'))
        first_name, last_name = caller_name.split(',')

        {
          first_name: first_name,
          last_name: last_name,
          referral: data.fetch('referrer', 'BlueskyPortal'),
          phone1: data.fetch('phone'),
          phone1_type: 'Cell',
          email: data.fetch('email'),
          notes: "Bluesky Portal Lead from #{data.fetch('referrer')}; Creative: #{data.fetch('creative')}; Referrer URL: #{data.fetch('referrer_url')}; Timestamp: #{data.fetch('timestamp')}; Submission: #{data.fetch('submission')}",
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
