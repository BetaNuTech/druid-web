module Leads
  module Adapters
    # Reference passthrough data adapter
    # This class corresponds to a LeadSource record with the slug value 'CallCenter'
    class CallCenter
      LEAD_SOURCE_SLUG = 'CallCenter'


      def initialize(params)
        @property_code = get_property_code(params)
        @data = filter_params(params)
      end

      # Return parsed data and meta-information as a Leads::Creator::Result
      def parse
        full_name = lookup_name
        @data['first_name'] = full_name.first
        @data['last_name'] = full_name.last
        @data['parser'] = 'CallCenter'
        lead = Lead.new(@data)
        lead.validate
        status = lead.valid? ? :ok : :invalid
        result = Leads::Creator::Result.new( status: status, lead: @data, errors: lead.errors, property_code: @property_code)
        return result
      end

      private

      # Used Twilio API to fetch CallerID information
      # CHARGES APPLY!
      def get_callerid(phone)
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

      def lookup_name
        first_name = @data.fetch('first_name',nil)
        last_name = @data.fetch('last_name',nil)
        phone = @data.fetch('phone1',nil)
        if phone.present? && ( ['Unknown', ' ','', nil].include?(first_name) )
          callerid_name = get_callerid(phone)
          if callerid_name
            cid_first_name, cid_last_name = callerid_name.split(' ')
            if cid_first_name.present?
              first_name = cid_first_name
              last_name = cid_last_name
            end
          end
        end
        [first_name, last_name]
      end

      def get_property_code(params)
        return params[:property_id]
      end

      # Filter for whitelisted params
      #
      # (extracted from LeadsController)
      def filter_params(params)
        valid_lead_params = Lead::ALLOWED_PARAMS - Lead::PRIVILEGED_PARAMS
        valid_preference_params = [{preference_attributes: LeadPreference::ALLOWED_PARAMS - LeadPreference::PRIVILEGED_PARAMS }]
        filterable_params = params.is_a?(ActionController::Parameters) ? params : ActionController::Parameters.new(params)
        return filterable_params.permit(*(valid_lead_params + valid_preference_params))
      end

    end
  end
end
