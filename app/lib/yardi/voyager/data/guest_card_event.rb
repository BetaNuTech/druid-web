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

        def self.from_lead_events(lead)
          out = []

          ### Lead state transitions as events
          #out += lead.transitions.where(remoteid: nil).map do |xtn|
            #GuestCardEvent.from_lead_state_transition(xtn)
          #end

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
            event.comments = "Lead created in Bluesky originating from #{lead.referral || 'Unknown'}"
            event.transaction_source = 'Referral'
            event.first_contact = true

            # TODO: assign better reason and event type
            event.reasons = 'Emailed'
            event.event_type = 'Other'
          else
            if lead_transition.current_state == 'disqualified'
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
