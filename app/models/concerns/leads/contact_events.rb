module Leads
  module ContactEvents
    extend ActiveSupport::Concern

    INCOMING_CALL_LEAD_EVENT_DESCRIPTION = 'Incoming call from Lead'.freeze

    class_methods do

      def backfill_incoming_call_contact_events(time_start: )
        leads = Lead.includes(:source, :contact_events).
          where(lead_sources: {slug: LeadSource::PHONE_SOURCES}).
          where('leads.created_at >= :created_at', { created_at: time_start})
        puts "*** Found #{leads.count} phone leads for processing"
        leads.each do |lead|
          first_contact_events = lead.contact_events.first_contact
          if first_contact_events.where(description: INCOMING_CALL_LEAD_EVENT_DESCRIPTION).any?
            next
          end
          if (event = first_contact_events.first)
            if event.timestamp > lead.created_at
              # Any subsequent first contact event will be superceded
              event.first_contact = false
              event.save
              lead.reload
            end
            lead.create_first_contact_event_for_incoming_call_leads(true)
          end
        end
      end

    end

    included do

      has_many :contact_events, dependent: :destroy

      after_create :create_first_contact_event_for_incoming_call_leads

      def create_first_contact_event_for_incoming_call_leads(force=false)
        if source&.phone_source? && !contact_events.first_contact.any?
          # TODO replace `create!` with `create`
          ContactEvent.create(
            lead_id: self.id,
            user_id: ( user_id || property&.primary_agent&.id ),
            timestamp: created_at,
            description: INCOMING_CALL_LEAD_EVENT_DESCRIPTION,
            first_contact: true,
            lead_time: 0
          )
        end
        true
      end

      def create_scheduled_action_contact_event(scheduled_action)
        if scheduled_action.lead_action&.is_contact?
          description = 'Completed a Contact action'
          timestamp = scheduled_action.completed_at || Time.now
          create_contact_event(timestamp: timestamp, description: description, article: scheduled_action)
        end
      end

      # Create contact event with optionally specified:
      #
      # timestamp: Time (default: Now)
      # description: String (default: 'Unspecified...')
      # lead_time: Integer (default: 1 minute),
      # article: Polymorphic (ScheduledAction or Message)
      #
      def create_contact_event(timestamp: nil, description: 'Unspecified Lead contact event' , lead_time: nil, article: nil)
        timestamp ||= Time.now
        event_user_id = ( user_id || property&.primary_agent&.id )
        is_first_contact = contact_events.where(first_contact: true).empty? && ( last_comm.nil? || timestamp < last_comm )

        self.first_comm ||= timestamp

        event = contact_events.create(
          user_id: event_user_id,
          timestamp: timestamp,
          description: description,
          first_contact: is_first_contact,
          lead_time: [lead_time || contact_lead_time(is_first_contact, timestamp), 1].max,
          article: article
        )

        self.last_comm = timestamp if ( last_comm.nil? || timestamp > last_comm )
        save

        event
      end

      handle_asynchronously :create_contact_event, queue: :low_priority

      def contact_lead_time(first_contact, timestamp)
        # Use created_at rather than first_comm so agents are not penalized for system delays
        # compare_timestamp = (first_contact ? first_comm : last_comm).to_time
        compare_timestamp = (first_contact ? created_at : last_comm).to_time
        
        ( [ ( timestamp.to_time - compare_timestamp ).to_i, 1 ].max / 60 ).to_i
      end

      def make_contact(timestamp: nil, description: nil, article: nil)
        description ||= 'Lead contacted (misc)'
        timestamp = timestamp || Time.now
        create_contact_event(timestamp: timestamp, description: description, article: article)
      end

      def lead_speed
        reportable? ? Statistic.lead_speed_grade(lead_speed_value) : 'N/A'
      end

      def lead_speed_value
        contact_events.first_contact.first&.lead_time || -1
      end

      def tenacity
        reportable? ? tenacity_value : 'N/A'
      end

      def tenacity_value
        [ ([[ contact_events.count.to_f, 0.01 ].max, 3.0].min / 3.0 ) * 10.0, 1.0 ].max
      end
    end
  end
end
