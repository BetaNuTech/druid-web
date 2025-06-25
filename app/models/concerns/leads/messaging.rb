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
    INITIAL_RESPONSE_LEAD_ACTION='First Contact'
    INITIAL_RESPONSE_REASON='First Contact'
    SMS_INITIAL_RESPONSE_TEMPLATE_NAME='New Lead Response Message-SMS-A'
    EMAIL_INITIAL_RESPONSE_TEMPLATE_NAME='New Lead Response Message-Email-A'
    STALE_AGE = 48

    included do

      has_many :messages, as: :messageable, dependent: :destroy
      attr_accessor :send_lead_automatic_reply

      def message_template_data
        {
          "lead_name" => name,
          "lead_title" => title,
          "lead_first_name" => first_name,
          "lead_last_name" => last_name,
          'lead_floorplan' => preference.try(:unit_type_name),
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
        destination = nil
        if respond_to?(:phone1_type) && respond_to?(:phone1) && phone1.present? && phone1_type == 'Cell'
          destination = phone1
        elsif respond_to?(:phone2_type) && respond_to?(:phone2) && phone2.present? && phone2_type == 'Cell'
          destination = phone2
        elsif respond_to?(:phone_type) && respond_to?(:phone) && phone_type == 'Cell'
          destination = phone
        elsif !respond_to?(:phone_type) && respond_to?(:phone)
          destination = phone
        else
          destination = [self&.phone1, self&.phone2].compact.first
        end
        destination = destination.present? ? Message.format_phone(destination) : nil

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

      def create_reply_task
        EngagementPolicyScheduler.new.create_lead_incoming_message_reply_task(self)
      end

      def handle_message_delivery(delivery)
        message = delivery.message # Get the Message

        if message.outgoing? && delivery.delivered? && message.delivered_at.present?
          # For outgoing messages, create a contact event.
          # The user for the contact event will default to self.user (Lead's assigned user)
          # inside create_contact_event.
          create_contact_event(
            article: message,
            timestamp: message.delivered_at,
            description: "Outgoing Message: #{message.subject}"
            # No user: param, so it defaults to self.user (lead's assigned user)
          )
          autocomplete_lead_contact_tasks(delivery)
        elsif message.incoming? && open?
          create_message_delivery_task(delivery)
        end
      end

      # Re-open the lead if it is disqualified or abandoned
      def requalify_if_disqualified
        return unless ( disqualified? || abandoned? )

        user = revisions.map(&:user).compact.last || property&.managers&.first
        requalify 
        trigger_event(event_name: :claim, user: user) if user
        save
        reload
      end

      # Automatically complete pending lead message reply tasks if this message was sent by the agent to a Lead
      def autocomplete_lead_contact_tasks(message_delivery)
        return false unless message_delivery&.message.present? && message_delivery&.message&.outgoing?

        lead = message_delivery.message.messageable
        return false unless lead.is_a?(Lead)

        # First try to find specific reply tasks
        reason = Reason.active.where(name: Reason::MESSAGE_REPLY_TASK_REASON).first
        action = LeadAction.active.where(name: LeadAction::MESSAGE_REPLY_TASK_ACTION).first
        
        if reason.present? && action.present?
          lead_contact_actions = lead.scheduled_actions.contact.pending
          lead_message_reply_tasks = lead_contact_actions.where(reason: reason, lead_action: action)
          
          if lead_message_reply_tasks.any?
            lead_message_reply_tasks.each{|t| t.complete! }
            return true
          end
        end
        
        # If no specific reply tasks were found, try to complete any pending contact tasks
        lead.scheduled_actions.contact.pending.each{|t| t.complete! }
        
        return true
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
        
        # Determine the correct template name based on message type and disposition
        if message_type == MessageType.sms
          if assent
            if disposition == :confirmation
              message_template_name = SMS_OPT_IN_CONFIRMATION_MESSAGE_TEMPLATE_NAME
            else
              message_template_name = SMS_OPT_IN_MESSAGE_TEMPLATE_NAME
            end
          else
            message_template_name = SMS_OPT_OUT_CONFIRMATION_MESSAGE_TEMPLATE_NAME
          end
        else
          # For email, we don't have specific opt-in/opt-out templates defined
          # So we'll use nil and handle it appropriately
          message_template_name = nil
        end
        
        message_template = MessageTemplate.where(name: message_template_name).first if message_template_name.present?
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
          comment_content = "SENT: #{message_template_name || "#{message_type_name} compliance message"}"
        else
          # Cannot send Message: send Error Notification
          message = Message.new()
          if !destination_present
            error_message = "No #{message_type_name} destination available"
          elsif !message_template.present?
            error_message = "Message template '#{message_template_name}' not found" if message_template_name.present?
            error_message ||= "No #{message_type_name} template configured for this action"
          else
            error_message = "Could not send #{message_type_name} message"
          end
          error = StandardError.new(error_message)
          comment_content = "NOT SENT: #{error_message}"
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

      # Request SMS authorization if not already requested or granted
      def request_sms_communication_authorization(force: false)

        # Send sms optin request if forced
        if force
          send_sms_optin_request
          return true
        end

        # Lead preference already set, don't send a duplicate authorization request
        return true if preference.optin_sms || preference.optin_sms_date.present?

        # Don't send a duplicate SMS compliance message unless forced (above)
        return true if messages.outgoing.sms.for_compliance.any?

        # Send an authorization request if there aren't any >=Prospect duplicates
        # with the same phone number
        if !duplicates_with_matching_phone.where("leads.state != 'open'").any?
          send_sms_optin_request
          return true
        end

        # There is a duplicate with the same phone number so Use that number's
        # SMS preferences
        authorizing_lead = duplicates_with_matching_phone.includes(:preference).
          where(lead_preferences: { optin_sms: true }).last
        if authorizing_lead.present?
          self.preference.optin_sms = true
          self.preference.optin_sms_date = authorizing_lead.preference.optin_sms_date
          self.preference.save
          reload
        end
      end

      # Ensure SMS messaging consent and compliance 
      def request_first_sms_authorization_if_open_and_unique
        if open? && !(messages.outgoing.sms.for_compliance.any? || any_sms_compliance_messages_for_recipient? )
          send_sms_optin_request
        else
          false
        end
      end

      def any_sms_compliance_messages_for_recipient?
        recipientid = message_recipientid(message_type: MessageType.sms)
        Message.outgoing.sms.compliance.where(recipientid: recipientid).any?
      end

      def any_marketing_messages_for_recipient?
        sms_recipientid = message_recipientid(message_type: MessageType.sms)
        email_recipientid = message_recipientid(message_type: MessageType.email)
        Message.outgoing.marketing.where(recipientid: [sms_recipientid, email_recipientid]).any?
      end

      # Messaging tasks after a lead is created
      def send_new_lead_messaging

        # Don't send if stale
        stale_hours = STALE_AGE
        if created_at.present? && ( created_at < stale_hours.hours.ago )
          message = "*** Lead[#{id}] new lead messaging was skipped because it is >#{stale_hours} old"
          Rails.logger.warn message
          note_reason = Reason.where(name: INITIAL_RESPONSE_REASON).first
          note_lead_action = LeadAction.where(name: MESSAGE_OPTIN_LEAD_ACTION).first
          note = Note.create(
            notable: self,
            lead_action: note_lead_action,
            reason: note_reason,
            content:  "New lead messaging was skipped because this record is >#{stale_hours}h old",
            classification: 'system'
          )
          return false
        end

        request_first_sms_authorization_if_open_and_unique
        lead_automatic_reply

        true
      end

      # Automatically send initial marketing messaging
      # typically for immediately after creation
      def lead_automatic_reply
        # Don't send to manually created leads
        return false if source === LeadSource.default

        # Don't send if we have contacted this recipient before
        return false if any_marketing_messages_for_recipient?

        unless Flipflop.enabled?(:lead_automatic_reply)
          message = "*** Lead[#{id}] Initial response messages not sent due to disabled 'lead_automatic_reply' feature setting. Envvar LEAD_AUTOMATIC_REPLY must be set to 'true'"
          Rails.logger.info message
          return false
        end

        unless property.setting_enabled?(:lead_auto_welcome)
          message = "*** Lead[#{id}] Initial response messages not sent due to disabled 'lead_auto_welcome' Property Appsetting"
          Rails.logger.info message
          return false
        end

        # send_initial_sms_response
        send_initial_email_response
      end

      def send_initial_sms_response
        note_reason = Reason.where(name: MESSAGE_DELIVERY_COMMENT_REASON).first
        note_lead_action = LeadAction.where(name: INITIAL_RESPONSE_LEAD_ACTION).first
        message_template_name = SMS_INITIAL_RESPONSE_TEMPLATE_NAME
        message_template = MessageTemplate.where(name: message_template_name).first

        return true unless message_sms_destination.present?

        if message_template.present? 
          message = Message.new_message(
            from: agent,
            to: self,
            message_type: MessageType.sms,
            message_template: message_template,
            classification: 'marketing'
          )
          message.save!
          message.deliver!
          message.reload
          comment_content = "SENT: #{message_template_name}"
        else
          comment_content = "Initial new lead response not sent because the template is missing (#{SMS_INITIAL_RESPONSE_TEMPLATE_NAME})"
        end

        note = Note.create!(
          notable: self,
          lead_action: note_lead_action,
          reason: note_reason,
          content: comment_content,
          classification: 'system'
        )
        
        return true
      end

      def send_initial_email_response
        note_reason = Reason.where(name: MESSAGE_DELIVERY_COMMENT_REASON).first
        note_lead_action = LeadAction.where(name: INITIAL_RESPONSE_LEAD_ACTION).first
        message_template_name = EMAIL_INITIAL_RESPONSE_TEMPLATE_NAME
        message_template = MessageTemplate.where(name: message_template_name).first

        return true unless message_email_destination.present?

        if message_template.present? 
          message = Message.new_message(
            from: agent,
            to: self,
            message_type: MessageType.email,
            message_template: message_template,
            classification: 'marketing'
          )
          message.save!
          message.deliver!
          message.reload
          comment_content = "SENT: #{message_template_name}"
        else
          comment_content = "Initial new lead response not sent because the template is missing (#{EMAIL_INITIAL_RESPONSE_TEMPLATE_NAME})"
        end

        note = Note.create!(
          notable: self,
          lead_action: note_lead_action,
          reason: note_reason,
          content: comment_content,
          classification: 'system'
        )
        
        return true
      end

      # Avoid calling directly to avoid duplicate requests
      # Use request_sms_communication_authorization or request_first_sms_authorization_if_open_and_unique
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

      # Allow resending sms opt-in message?
      #
      # ALWAYS true
      def resend_opt_in_message?
        #messages.for_compliance.empty? ||
        #( messages.for_compliance.exists? &&
          #messages.for_compliance.last.failed? )

        # Always allow resending opt_in message
        true
      end

    end
  end
end
