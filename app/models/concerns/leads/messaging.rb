module Leads
  module Messaging
    extend ActiveSupport::Concern

    MESSAGE_DELIVERY_COMMENT_REASON = 'Follow-Up'
    MESSAGE_OPTOUT_LEAD_ACTION = 'Lead Email/SMS Opt-Out'
    MESSAGE_OPTIN_LEAD_ACTION = 'Lead Email/SMS Opt-In'
    MESSAGE_LEAD_PREFERENCE_SET = 'Lead Preference Set'
    SMS_OPT_IN_MESSAGE_TEMPLATE_NAME='SMS Opt-In Request'
    SMS_OPT_IN_CONFIRMATION_MESSAGE_TEMPLATE_NAME='SMS Opt-In Confirmation'
    SMS_OPT_OUT_CONFIRMATION_MESSAGE_TEMPLATE_NAME='SMS Opt-Out Confirmation'

    included do

      has_many :messages, as: :messageable, dependent: :destroy
      #before_save :set_optin_sms_date

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
        preference&.optout_email?
      end

      def optin_email?
        !optout_email?
      end

      def optout_email!
        if preference.present?
          preference.optout_email!
          create_optout_comment(content: "Lead used email unsubscribe link to opt out of automated emails")
        end
      end

      def optin_email!
        if preference.present?
          preference.optin_email!
          create_optin_comment(content: "Lead used email unsubscribe link to opt back into automated emails")
        end
      end

      def optin_sms?
        preference&.optin_sms?
      end

      def optout_sms?
        !optin_sms?
      end

      def optin_sms!
        if preference.present?
          preference.optin_sms!
          create_optin_comment(content: "Lead used email unsubscribe link to opt back into automated sms messaging")
        end
      end

      def optout_sms!
        if preference.present?
          preference.optout_sms!
          create_optin_comment(content: "Lead used email unsubscribe link to opt out of automated sms messaging")
        end
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
        note_content = "%{direction} a %{message_type} message %{tofrom} the Lead : %{subject}" % {
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

      def create_message_delivery_task(message_delivery)
        message = message_delivery.message
        if message.incoming?
          EngagementPolicyScheduler.new.
            create_lead_incoming_message_reply_task(message)
        end
      end

      def handle_message_delivery(message_delivery)
        if message_delivery&.delivered_at.present?
          self.last_comm = message_delivery.delivered_at
          save
          preference&.handle_message_response(message_delivery)
          create_message_delivery_comment(message_delivery)
          create_message_delivery_task(message_delivery)
        end
      end

      # Send communication compliance message
      #
      # send_compliance_message(
      #   message_type: MessageType.sms|MessageType.email,
      #   disposition: :request|:confirmation,
      #   assent: true|false)
      def send_compliance_message(message_type:, disposition:, assent:)
        # Abort if contact information for message type is not present
        case message_type
        when MessageType.sms
          return true unless message_sms_destination.present?
        when MessageType.email
          return true unless message_email_destination.present?
        end

        note_lead_action_name = assent ? MESSAGE_OPTIN_LEAD_ACTION : MESSAGE_OPTOUT_LEAD_ACTION
        note_lead_action = LeadAction.where(name: note_lead_action_name).first
        note_reason = Reason.where(name: MESSAGE_DELIVERY_COMMENT_REASON).first
        message_type_name = message_type&.name&.downcase
        message_template_name = "Leads::Messaging::%s_%s%s_MESSAGE_TEMPLATE_NAME" % [
          message_type_name&.upcase,
          ( assent ? 'OPT_IN' : 'OPT_OUT' ),
          ( disposition == :confirmation ? '_CONFIRMATION'  : '' )
        ]
        message_template_name = Object.const_get(message_template_name) rescue nil
        message_template = MessageTemplate.where(name: message_template_name).first
        destination_present = ( self.send("message_" + message_type_name + "_destination").present? rescue false )

        if destination_present && message_template.present?
          # Send Message to Lead
          message = Message.new_message(
            from: agent,
            to: self,
            message_type: message_type,
            message_template: message_template,
            classification: 'compliance'
          )
          message.save!
          message.deliver!
          message.reload
          comment_content = "SENT: #{message_template_name}"
        else
          # Cannot send Message: send Error Notification
          message = Message.new()
          error_message = "Could not send SMS opt-in request"
          errors[:errors] << error_message
          error = StandardError.new(error_message)
          if message_template.nil?
            errors[:errors] << "Missing Message Template: '#{message_template_name}'"
          end
          if message_sms_destination.nil?
            errors[:errors] << "Lead does not have a Phone Number"
          end
          #ErrorNotification.send(error,errors)
          comment_content = "NOT SENT: #{message_template_name} -- #{errors[:errors].join('; ')}"
        end

        # Add activity entry to Lead timeline
        note = Note.create!( # create_event_note
          notable: self,
          lead_action: note_lead_action,
          reason: note_reason,
          content: comment_content,
          classification: 'system'
        )

      end

      def send_sms_optin_request
        send_compliance_message(
          message_type: MessageType.sms,
          disposition: :request,
          assent: true
        )
      end

      def send_sms_optin_confirmation
        send_compliance_message(
          message_type: MessageType.sms,
          disposition: :confirmation,
          assent: true
        )
      end

      def send_sms_optout_confirmation
        send_compliance_message(
          message_type: MessageType.sms,
          disposition: :confirmation,
          assent: false
        )
      end

      def opt_in_message_sent?
        messages.for_compliance.exists?
      end

      def resend_opt_in_message?
        messages.for_compliance.empty? ||
        ( messages.for_compliance.exists? &&
          messages.for_compliance.last.failed? )
      end

    end
  end
end
