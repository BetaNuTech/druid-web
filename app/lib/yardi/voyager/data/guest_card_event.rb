module Yardi
  module Voyager
    module Data
      class GuestCardEvent
        REMOTE_DATE_FORMAT = GuestCard::REMOTE_DATE_FORMAT
        EVENT_TYPES = ['Appointment', 'Call', 'Walk-In', 'Email', 'Return Visit', 'Letter', 'Show', 'Other', 'Application', 'Approval', 'Cancellation', 'Im Canceling Guest', 'Rejection', 'Renewal', 'Security Deposit Override', 'Wait list']
        EVENT_REASONS = ['Add/Lost Roommate', 'Apartment List', 'Applied', 'Bought House', 'Consult with roommate/spouse', 'Decided not to Move', 'Deposit (cannot afford)', 'Duplicate', 'Duplicate Opportunity', 'Emailed', 'Felony', 'Lease Terms', 'Leasehawk - First Response', 'Location', 'Lost Job', 'Lost to Competitor', 'Made Appointment', 'Need by date passed', 'No Availability', 'No contact', 'No Valid ID', 'Pets (restricted breed or #)', 'Phone Number Incorrect', 'Price', 'Reapply', 'Rented House, duplex, condo', 'Size of Apartment', 'Spoke to', 'Too Many Occupants', 'Utilities', 'Voicemail']

        ATTRIBUTES = [
          :remoteid,
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
          out += lead.transitions.where(remoteid: nil).map do |xtn|
            agent = ( xtn.lead.user.present? ?
                     { first_name: xtn.lead.user.profile.first_name,
                       last_name: xtn.lead.user.profile.last_name } : {} )

            event = GuestCardEvent.new
            event.remoteid = xtn.remoteid || ''
            event.date = xtn.created_at
            event.agent = agent

            if (xtn.last_state == 'none' && xtn.current_state == 'open')
              event.comments = "Lead created in Druid originating from #{lead.referral || 'Unknown'}"
              event.transaction_source = 'Referral'
              event.first_contact = true

              # TODO: assign better reason and event type
              event.reasons = 'Emailed'
              event.event_type = 'Other'
            else
              event.reasons = 'Emailed'
              event.event_type = 'Other'
              event.first_contact = false
              event.comments = "Lead transitioned from %s to %s (classified as %s) -- [LeadTransition:%s])" % [xtn.last_state, xtn.current_state, ( xtn.classification || '-'), xtn.id]
            end

            event
          end

          out += lead.scheduled_actions.complete.where(remoteid: nil).map do |sa|
            agent = ( sa.target.user.present? ?
                     { first_name: sa.target.user.profile.first_name,
                       last_name: sa.target.user.profile.last_name } : {} )
            comments = "%s -- [ScheduledAction:%s])" % [sa.summary, sa.id]

            event = GuestCardEvent.new
            event.remoteid = sa.remoteid || ''
            event.date = sa.created_at
            event.event_type = 'Other'
            event.reasons = 'Emailed'
            event.first_contact = 'false'
            event.agent = agent
            event.comments = comments
            #event.transaction_source = 'Referral'
            event
          end

          out = out.sort_by{|event| event.date}

          return out
        end

      end
    end
  end
end