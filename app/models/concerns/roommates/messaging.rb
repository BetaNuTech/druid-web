module Roommates
  module Messaging
    extend ActiveSupport::Concern

    MESSAGE_DELIVERY_COMMENT_REASON = 'Follow-Up'

    included do

      has_many :messages, as: :messageable, dependent: :destroy

      def message_template_data
        {
          "lead_name" => name,
          "lead_title" => nil,
          "lead_first_name" => first_name,
          "lead_last_name" => last_name,
          'lead_floorplan' => lead.preference.try(:unit_type_name),
          "agent_name" => user.try(:name),
          "agent_first_name" => user.try(:first_name),
          "agent_last_name" => user.try(:last_name),
          "agent_title" => user.try(:team_title),
          "property_name" => property.try(:name),
          "property_address" => property.try(:address),
          "property_address_html" => property.try(:address_html),
          'property_city' => property.try(:city),
          'property_amenities' => property.try(:amenities),
          'property_website' => property.try(:website),
          'property_phone' => property.try(:formatted_phone_number),
          'property_school_district' => property.try(:school_district),
          'property_application_url' => property.try(:application_url),
          'property_virtual_tour_booking_url' => property.try(:virtual_tour_booking_url),
          'property_in_person_tour_booking_url' => property.try(:in_person_tour_booking_url),
          'html_email_header_image' => ("%s://%s/email_header_sapphire-620.png" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST','')]),
          'email_business_logo' => ("%s://%s/bluecrest_logo_small.png" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST','')]),
          'email_housing_logo' => ("%s://%s/equal_housing_logo.png" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST','')]),
          'email_unsubscribe_link' => ("%s://%s/messaging/preferences?id=%s" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST',''), id]),
        }
      end

      def message_recipientid(message_type:)
        return case message_type
      when -> (mt) { mt&.email? }
        message_email_destination
      when -> (mt) { mt&.sms? }
        message_sms_destination
      else
        'unknown'
      end
    end

    def message_sms_destination
      return phone.present? ? Message.format_phone(phone) : nil
    end

    def message_email_destination
      return try(:email)
    end

    def message_types_available
      types = []
      types << MessageType.sms if permit_sms_messaging?
      types << MessageType.email if permit_email_messaging?
      return types
    end

    def permit_sms_messaging?
      !( MessageType.sms.disabled? rescue false ) && optin_sms? && message_sms_destination.present?
    end

    def permit_email_messaging?
      !( MessageType.email.disabled? rescue false ) && !optout_email? && message_email_destination.present?
    end

    def optout_email?
      !email_allowed?
    end

    def optin_email?
      !optout_email?
    end

    def optout_email!
      self.email_allowed = true
      save
    end

    def optin_email!
      self.email_allowed = true
      save
    end

    def optin_sms?
      sms_allowed?
    end

    def optout_sms?
      !optin_sms?
    end

    def optin_sms!
      self.optin_sms = true
      save
    end

    def optout_sms!
      self.optin_sms = false
      save
    end

    def create_message_delivery_comment(message_delivery)
      msg = message_delivery.message
      note_content = "%{direction} a %{message_type} message %{tofrom} the Roommate : %{subject}" % {
        direction: msg.incoming? ? "Received" : "Sent",
        message_type: msg.message_type.name,
        tofrom: msg.incoming? ? "from" : "to",
        subject: ( msg.subject || '' )[0..30]
      }
      note_reason = Reason.where(name: MESSAGE_DELIVERY_COMMENT_REASON).first
      # create_event_note
      Note.create( # create_event_note
                  notable: self,
                  reason: note_reason,
                  content: note_content,
                  classification: 'system'
                 )
    end

    def handle_message_delivery(message_delivery)
      # NOOP
      true
    end

  end
end
end
