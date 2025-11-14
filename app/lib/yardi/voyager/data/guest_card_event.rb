module Yardi
  module Voyager
    module Data
      class GuestCardEvent
        REMOTE_DATE_FORMAT = GuestCard::REMOTE_DATE_FORMAT

        # Event types vary per property
        #EVENT_TYPES = ['Appointment', 'Call', 'Walk-In', 'Email', 'Return Visit', 'Letter', 'Show', 'Other', 'Application', 'Approval', 'Cancellation', 'Im Canceling Guest', 'Rejection', 'Renewal', 'Security Deposit Override', 'Wait list']

        EVENT_REASONS = ['Add/Lost Roommate', 'Apartment List', 'Applied', 'Bought House', 'Consult with roommate/spouse', 'Decided not to Move', 'Deposit (cannot afford)', 'Duplicate', 'Duplicate Opportunity', 'Emailed', 'Felony', 'Lease Terms', 'Leasehawk - First Response', 'Location', 'Lost Job', 'Lost to Competitor', 'Made Appointment', 'Need by date passed', 'No Availability', 'No contact', 'No Valid ID', 'Pets (restricted breed or #)', 'Phone Number Incorrect', 'Price', 'Reapply', 'Rented House, duplex, condo', 'Size of Apartment', 'Spoke to', 'Too Many Occupants', 'Utilities', 'Voicemail']

        ATTRIBUTES = [
          :remoteid,
          :idtype,
          :date,
          :event_type,
          :reasons,
          :first_contact,
          :agent,
          :comments,
          :transaction_source
        ]

        attr_accessor *ATTRIBUTES

        def self.from_lead_events(lead, agent: nil)
          out = []

          ### Lead state transitions as events
          #transition_events = lead.transitions.where(remoteid: nil).map do |xtn|
          # Only send initial lead creation event as first contact
          transition_events = lead.transitions.where(remoteid: nil, last_state: 'none', current_state: 'open')
          out += transition_events.map do |xtn|
            GuestCardEvent.from_lead_state_transition(xtn)
          end

          ### Completed Tasks as GuestCard Events
          completed_actions = lead.scheduled_actions.completed.where(remoteid: nil)
          out += completed_actions.map do |sa|
            GuestCardEvent.from_scheduled_action(sa)
          end

          ### Pending Meetings as GuestCard Events
          pending_meetings = lead.scheduled_actions.includes(:lead_action).pending.
            where(lead_actions: {notify: true}, scheduled_actions: {remoteid: [ nil, '' ]})
          out += pending_meetings.map do |sa|
            GuestCardEvent.from_scheduled_action(sa)
          end

          # Override agent if provided (for Lea AI "Admin" or other special cases)
          if agent.present?
            out.each do |event|
              event.agent = {
                first_name: agent.profile&.first_name || agent.first_name || '',
                last_name: agent.profile&.last_name || agent.last_name || ''
              }
            end
          end

          # Ensure there's always a first contact event
          # If no first contact event exists, create one using the lead's created_at date
          has_first_contact = out.any? { |event| event.first_contact == true || event.first_contact == 'true' }

          if !has_first_contact && lead.remoteid.blank?
            # Create a first contact event from the lead's creation date
            first_contact_event = GuestCardEvent.new
            first_contact_event.remoteid = ''
            first_contact_event.date = lead.created_at || DateTime.current
            first_contact_event.event_type = 'Other'
            first_contact_event.reasons = 'Emailed'
            first_contact_event.first_contact = true
            first_contact_event.comments = "Lead created in Bluesky originating from #{lead.referral || lead.source&.name || 'Unknown'}"
            first_contact_event.transaction_source = 'Referral'

            # Use the provided agent or fall back to the lead's creditable agent
            if agent.present?
              first_contact_event.agent = {
                first_name: agent.profile&.first_name || agent.first_name || '',
                last_name: agent.profile&.last_name || agent.last_name || ''
              }
            else
              first_contact_event.agent = {}
            end

            out << first_contact_event
          end

          out = out.sort_by{|event| event.date}

          return out
        end

        def self.from_lead_state_transition(lead_transition)
          agent = ( lead_transition.lead.user.present? ?
                   { first_name: lead_transition.lead.user.profile.first_name,
                     last_name: lead_transition.lead.user.profile.last_name } : {} )

          event = GuestCardEvent.new
          event.remoteid = lead_transition.remoteid || ''
          event.date = lead_transition.created_at
          event.agent = agent

          if (lead_transition.last_state == 'none' && lead_transition.current_state == 'open')
            event.comments = "Lead created in Bluesky originating from #{lead_transition.lead.referral || 'Unknown'}"
            event.transaction_source = 'Referral'
            event.first_contact = true

            # TODO: assign better reason and event type
            event.reasons = 'Emailed'
            event.event_type = 'Other'
          else
            if lead_transition.current_state == 'invalidated'
              event.event_type = 'Cancel'
            else
              event.event_type = 'Other'
            end
            event.comments = "Lead transitioned from %s to %s (classified as %s) -- [LeadTransition:%s])" % [lead_transition.last_state, lead_transition.current_state, ( lead_transition.classification || '-'), lead_transition.id]
            event.reasons = 'Emailed'
            event.first_contact = false
          end

          event
        end

        def self.from_scheduled_action(scheduled_action)
          agent = ( scheduled_action.user.present? ?
                   { first_name: scheduled_action.user.profile&.first_name,
                     last_name: scheduled_action.user.profile&.last_name } : {} )
          comments = "%s -- [ScheduledAction:%s])" % [scheduled_action.summary, scheduled_action.id]

          case scheduled_action.lead_action&.name
          when LeadAction::SHOWING_ACTION_NAME
            event_type = 'Show'
            idtype = scheduled_action.article&.remoteid
          else
            event_type = 'Other'
            idtype = nil
          end

          event = GuestCardEvent.new
          event.remoteid = scheduled_action.remoteid || ''
          event.idtype = idtype
          event.date = scheduled_action.created_at
          event.event_type = event_type
          event.reasons = 'Emailed'
          event.first_contact = 'false'
          event.agent = agent
          event.comments = comments
          event
        end

      end
    end
  end
end
