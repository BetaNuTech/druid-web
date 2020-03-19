module Leads
  module Messaging
    extend ActiveSupport::Concern

    MESSAGE_DELIVERY_COMMENT_REASON = 'Follow-Up'
    MESSAGE_OPTOUT_LEAD_ACTION = 'Lead Email Opt-Out'
    MESSAGE_OPTIN_LEAD_ACTION = 'Lead Email Opt-In'
    MESSAGE_LEAD_PREFERENCE_SET = 'Lead Preference Set'

    included do

      has_many :messages, as: :messageable, dependent: :destroy

      def message_template_data
        {
          "lead_name" => name,
          'lead_floorplan' => preference.try(:unit_type_name),
          "agent_name" => user.try(:name),
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
          'html_email_header_image' => ("%s://%s/email_header_sapphire-620.png" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST','')]),
          'email_bluestone_logo' => ("%s://%s/bluestone_logo_small.png" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST','')]),
          'email_housing_logo' => ("%s://%s/equal_housing_logo.png" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST','')]),
          'email_unsubscribe_link' => ("%s://%s/messaging/preferences?id=%s" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST',''), id]),
        }
      end

      def message_recipientid(message_type:)
        return case message_type
          when -> (mt) { mt.email? }
            message_email_destination
          when -> (mt) { mt.sms? }
            message_sms_destination
          else
            'unknown'
          end
      end

      def message_sms_destination
        destination = nil
        if respond_to?(:phone1_type) && respond_to?(:phone1) && phone1_type == 'Cell'
          destination = phone1
        elsif respond_to?(:phone2_type) && respond_to?(:phone2) && phone2_type == 'Cell'
          destination = phone2
        elsif respond_to?(:phone_type) && respond_to?(:phone) && phone_type == 'Cell'
          destination = phone
        elsif !respond_to?(:phone_type) && respond_to?(:phone)
          destination = phone
        else
          destination = [self&.phone1, self&.phone2].compact.first
        end
        destination = Message.format_phone(destination)
        return destination
      end

      def message_email_destination
        return try(:email)
      end

      def message_types_available
        types = []
        types << MessageType.active.sms if message_sms_destination.present?
        types << MessageType.active.email if message_email_destination.present?
        return types
      end

      def optout!
        if preference.present?
          preference.optout!
          create_optout_comment(content: "Lead used email unsubscribe link to opt out of automated emails")
        end
      end

      def optin!
        if preference.present?
          preference.optin!
          create_optin_comment(content: "Lead used email unsubscribe link to opt back into automated emails")
        end
      end

      def optout?
        preference.optout? if preference.present?
      end

      def create_optout_comment(content:)
        note_lead_action = LeadAction.where(name: MESSAGE_OPTOUT_LEAD_ACTION).first
        note_reason = Reason.where(name: MESSAGE_LEAD_PREFERENCE_SET).first
        note = Note.create( # create_event_note
          lead_action: note_lead_action,
          notable: self,
          reason: note_reason,
          content: content,
          classification: 'system'
        )
      end

      def create_optin_comment(content:)
        note_lead_action = LeadAction.where(name: MESSAGE_OPTIN_LEAD_ACTION).first
        note_reason = Reason.where(name: MESSAGE_LEAD_PREFERENCE_SET).first
        note = Note.create( # create_event_note
          lead_action: note_lead_action,
          notable: self,
          reason: note_reason,
          content: content,
          classification: 'system'
        )
      end

      def create_message_delivery_comment(message_delivery)
        msg = message_delivery.message
        note_content = "%{direction} a %{message_type} message %{tofrom} the Lead" % {
          direction: msg.incoming? ? "Received" : "Sent",
          message_type: msg.message_type.name,
          tofrom: msg.incoming? ? "from" : "to"
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

      def create_message_delivery_task(message_delivery)
        message = message_delivery.message
        if message.incoming?
          EngagementPolicyScheduler.new.
            create_lead_incoming_message_reply_task(message)
        end
      end

      def handle_message_delivery(message_delivery)
        if message_delivery&.delivered_at.present?
          create_message_delivery_comment(message_delivery)
          create_message_delivery_task(message_delivery)
          self.last_comm = message_delivery.delivered_at
          save
        end
      end

    end
  end
end
