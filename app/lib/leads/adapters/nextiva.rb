module Leads
  module Adapters
    class Nextiva
      LEAD_SOURCE_SLUG = 'Nextiva'

      # Description  : Raw CDR data is posted from an FTP server

      def initialize(params)
        @property_code = get_property_code(params)
        @data = filter_params(params)
      end

      def parse
        return build(data: map(@data), property_code: @property_code)
      end

      private

      # Example data with empty fields omitted
      # {
      #   "OtherPartyNamePresIndic" => "Public",
      #   "UserNumber" => "1401",
      #   "Group" => "2628709G",
      #   "CLIDPermitted" => "Yes",
      #   "CallingNumber" => "+14047472363",
      #   "TerminationCause" => "017",
      #   "OriginalCalledNumber" => "+17708692462",
      #   "AnswerIndic" => "No",
      #   "ExternalTrackingId" => "024239f6-3a48-4c75-8fc9-66465f944e54",
      #   "Route" => "Group",
      #   "RedirectingReason" => "hunt-group",
      #   "GroupNumber" => "+17708692462",
      #   "StartTime" => "20210316182119.602",
      #   "Call-Duration-In-Millis" => "0",
      #   "ServiceProvider" => "3584583",
      #   "CallingPresentationIndic" => "Public",
      #   "LocalCallId" => "9175900217:0",
      #   "CalledNumber" => "1401",
      #   "RemoteCallid" => "9175900213:1",
      #   "CallCategory" => "private",
      #   "Direction" => "Terminating",
      #   "RecordId" => "00263774420050569D63FB20210316182119.6020-070000",
      #   "OtherPartyName" => "WIRELESS CALLER",
      #   "OriginalCalledReason" => "hunt-group",
      #   "ASCallType" => "Group",
      #   "Type" => "Normal",
      #   "RedirectingPresentationIndic" => "Public",
      #   "ReleaseTime" => "20210316182119.660",
      #   "ReleasingParty" => "local",
      #   "NAMEPermitted" => "Yes",
      #   "OriginalCalledPresentationIndic" => "Public",
      #   "RedirectingNumber" => "+17708692462",
      #   "NetworkType" => "VoIP",
      #   "ChargeIndic" => "n",
      #   "UserId" => "darby.1401@nextiva.com"
      # }

      #
      def map(data)
        callerid = ( data["OtherPartyName"] || "Unknown" )
        first_name, last_name = callerid.split.map{|n| sanitize(n || '')}
        did = PhoneNumber.format_phone(data["OriginalCalledNumber"])
        phone = sanitize(PhoneNumber.format_phone(data["CallingNumber"]))
        record_id = data["RecordId"]
        timestamp = ( Time.parse(data["StartTime"]).to_s rescue data["StartTime"] )
        notes = "Incoming call from #{phone} (#{callerid}) to #{did} at #{timestamp}. Record ID: [#{record_id}]"
        referral = MarketingSource.where(tracking_number: did).first&.name || 'Call'

        return {
          title: '',
          first_name: first_name,
          last_name: last_name,
          referral: referral,
          phone1: phone,
          phone2: nil,
          email: nil,
          fax: nil,
          notes: notes,
          tempid: record_id,
          first_comm: timestamp,
          preference_attributes: {
            raw_data: {plain: data}.to_json
          }
        }
      end

      def build(data:, property_code:)
        lead = Lead.new(data)
        lead.validate
        if matching_lead?(lead)
          lead.errors.add(:phone1, 'Duplicate Nextiva Call Record') if matching_lead?(lead)
          status = :invalid
        else
          status = lead.valid? ? :ok : :invalid
        end
        result = Leads::Creator::Result.new( status: status, lead: data, errors: lead.errors, property_code: property_code)
        return result
      end

      def get_property_code(params)
        return params[:property]
      end

      def filter_params(params)
        # STUB
        params
      end

      def sanitize(value)
        return ActionController::Base.helpers.sanitize(value)
      end

      def matching_lead?(lead)
        time_window = ( ( lead.first_comm || DateTime.current ) - 1.day )..DateTime.current
        Lead.where(created_at: time_window).where("notes ILIKE '%#{lead.tempid}%'")
          .or(Lead.where(phone1: lead.phone1))
          .any?
      end

    end
  end
end
