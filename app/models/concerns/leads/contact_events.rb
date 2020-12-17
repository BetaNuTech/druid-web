module Leads
  module ContactEvents
    extend ActiveSupport::Concern

    included do

      has_many :contact_events, dependent: :destroy

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
        event = nil
        first_contact = contact_events.where(first_contact: true).empty? && ( last_comm.nil? || timestamp < last_comm )
        self.first_comm ||= timestamp
        event = contact_events.create(
          user_id: user_id,
          timestamp: timestamp,
          description: description,
          first_contact: first_contact,
          lead_time: [lead_time || contact_lead_time(first_contact, timestamp), 1].max,
          article: article
        ) if user_id.present?
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
        Statistic.lead_speed_grade(contact_events.first_contact.first&.lead_time || -1)
      end
    end
  end
end
