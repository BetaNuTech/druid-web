module Leads
  module ContactEvents
    extend ActiveSupport::Concern

    INCOMING_CALL_LEAD_EVENT_DESCRIPTION = 'Incoming call from Lead'.freeze

    class_methods do

      def backfill_incoming_call_contact_events(time_start: )
        leads = Lead.includes(:source, :contact_events).
          where(lead_sources: {slug: LeadSource::PHONE_SOURCES}).
          where('leads.created_at >= :created_at', { created_at: time_start})
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
          timestamp = scheduled_action.completed_at || DateTime.current
          
          # Check if we can get a valid user_id before trying to create contact event
          potential_user_id = user_id || property&.primary_agent&.id || scheduled_action.user_id
          
          if potential_user_id.nil?
            Rails.logger.warn "Cannot create contact event for scheduled action #{scheduled_action.id} - no valid user_id available"
            return nil
          end
          
          create_contact_event({ timestamp: timestamp, description: description, article: scheduled_action })
        end
      end

      # Create contact event with optionally specified:
      #
      # timestamp: Time (default: Now)
      # description: String (default: 'Unspecified...')
      # lead_time: Integer (default: 1 minute),
      # article: Polymorphic (ScheduledAction or Message)
      #
      # Lead owner is given credit for any lead contact events to prevent unfair tenacity scores
      #
      def create_contact_event(options)
        timestamp = options.fetch(:timestamp, DateTime.current)
        description = options.fetch(:description, 'Unspecified Lead contact event')
        lead_time = options.fetch(:lead_time, nil)
        article = options.fetch(:article, nil)
        event_user_id = ( user_id || property&.primary_agent&.id )
        
        # If we still don't have a user_id and article is a scheduled action, use its user_id
        if event_user_id.nil? && article.is_a?(ScheduledAction) && article.user_id.present?
          event_user_id = article.user_id
        end
        
        # If we still don't have a user_id, we cannot create a contact event
        if event_user_id.nil?
          Rails.logger.error "Cannot create contact event for lead #{id} - no valid user_id found"
          return nil
        end
        
        is_first_contact = contact_events.where(first_contact: true).empty? && ( last_comm.nil? || timestamp < last_comm )

        self.first_comm ||= timestamp

        event = contact_events.build(
          user_id: event_user_id,
          timestamp: timestamp,
          description: description,
          first_contact: is_first_contact,
          lead_time: [lead_time || contact_lead_time(is_first_contact, timestamp), 1].max,
          article: article
        )
        
        unless event.valid?
          Rails.logger.error "Contact event validation failed for lead #{id}: #{event.errors.full_messages.join(', ')}"
          return nil
        end
        
        event.save!

        self.last_comm = timestamp if ( last_comm.nil? || timestamp > last_comm )
        save!

        event
      end

      def contact_lead_time(first_contact, timestamp)
        # Use created_at rather than first_comm so agents are not penalized for system delays
        compare_timestamp = (first_contact ? created_at : last_comm)

        # Calculate simple elapsed time in minutes (for 48-hour cap check)
        simple_elapsed_minutes = ( [ ( timestamp.to_time - compare_timestamp.to_time ).to_i, 1 ].max / 60 ).to_i

        # Only apply business hours calculation for first 48 hours (2880 minutes)
        # Anything over 48 hours is already graded as 'C', so optimization not needed
        if simple_elapsed_minutes > 2880
          return simple_elapsed_minutes
        end

        # Use property's business hours if available
        if property.present? && property.respond_to?(:working_hours_difference_in_time)
          begin
            business_hours_minutes = property.working_hours_difference_in_time(compare_timestamp, timestamp)
            # Return business hours calculation, with minimum of 1 minute
            return [business_hours_minutes, 1].max
          rescue => e
            Rails.logger.warn "Failed to calculate business hours lead time for lead #{id}: #{e.message}"
            # Fall back to simple calculation if business hours calculation fails
            return simple_elapsed_minutes
          end
        end

        # Fallback to simple calculation if no property or business hours unavailable
        simple_elapsed_minutes
      rescue
        1
      end

      def make_contact(timestamp: nil, description: nil, article: nil)
        description ||= 'Lead contacted (misc)'
        timestamp = timestamp || DateTime.current
        create_contact_event({ timestamp: timestamp, description: description, article: article })
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
