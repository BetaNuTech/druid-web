module Leads
  module Adapters
    class YardiVoyager
      LEAD_SOURCE_SLUG = 'YardiVoyager'
      DEFAULT_RENTAL_TYPE = 'Residential'

      attr_reader :property, :property_code, :lead_source, :data, :params

      # Returns all active Property ID's defined as PropertyListings in the database
      #
      # Returns:
      # [ { name: 'Property Name', code: 'voyagerpropertyid', property: #<Property> } ... ]
      def self.property_codes
        PropertyListing.includes(:source, :property).
            active.
            where(lead_sources: {slug: LEAD_SOURCE_SLUG}).
          map do |pl|
            {name: pl.property.name, code: pl.code, property: pl.property}
          end
      end

      # This Class interacts with the YardiVoyager API in the Yardi::Voyager namespace
      # Use it to send Leads to YardiVoyager, or download Leads, UnitTypes, and Units
      #
      # Accepts a Hash at minimum containing a valid
      # PropertyListing code for the YardiVoyager LeadSource
      #
      # Ex: { property_code: 'marble'}
      def initialize(params)
        @params = params
        @lead_source =  get_lead_source
        if @lead_source.nil?
          msg = "Lead Adapter Error! LeadSource record for #{LEAD_SOURCE_SLUG} is missing!"
          err = StandardError.new(msg)
          ErrorNotification.send(err, @params)
          Rails.logger.error msg
          raise err
        end
        @property_code = get_property_code(@params)
        @property = property_for_listing_code(@property_code)
      end

      # Fetch New Leads from YardiVoyager
      # or progress Lead state if the Lead is already in Druid
      def processLeads
        @data = fetch_GuestCards(@property_code)
        leads = []
        ActiveRecord::Base.transaction do
          leads = collection_from_guestcards(@data)
          leads.each{|l| l.save}
        end
        return leads
      end

      # Fetch New UnitTypes from YardiVoyager
      def processUnitTypes
        @data = fetch_Floorplans(@property_code)
        unit_types = []
        ActiveRecord::Base.transaction do
          unit_types = collection_from_floorplans(@data)
          unit_types.each{|l| l.save}
        end
        return unit_types
      end

      # Fetch New Units from YardiVoyager
      def processUnits
        @data = fetch_Units(@property_code)
        units = []
        ActiveRecord::Base.transaction do
          units = collection_from_yardi_units(@data)
          units.each{|l| l.save}
        end
        return units
      end

      # Send new/unsynced Leads to Yardi Voyager
      def sendLeads(leads)
        updated_leads = []
        ActiveRecord::Base.transaction do
          updated_leads = send_Leads(leads)
          updated_leads.map{|l| l.save }
        end
        return updated_leads
      end

      private

      def collection_from_yardi_units(units)
        return units.map{|unit| unit_from_yardi_unit(unit)}
      end

      def unit_from_yardi_unit(yardi_unit)
        unit = Unit.where(property_id: @property.id, remoteid: yardi_unit.remoteid).first || Unit.new
        unit_type = UnitType.where(property_id: @property.id, remoteid: yardi_unit.floorplan_id).first
        rental_type = RentalType.where(name: DEFAULT_RENTAL_TYPE).first

        unit.property_id ||= @property.id
        unit.unit_type_id ||= unit_type.try(:id)
        unit.rental_type_id ||= rental_type.try(:id)
        unit.remoteid ||= yardi_unit.remoteid
        unit.unit ||= yardi_unit.name

        unit.sqft = yardi_unit.sqft
        unit.bedrooms = yardi_unit.bedrooms
        unit.bathrooms = yardi_unit.bathrooms
        unit.lease_status = yardi_unit.lease_status
        unit.occupancy = yardi_unit.occupancy
        unit.available_on = yardi_unit.available_on

        return unit
      end

      def collection_from_floorplans(floorplans)
        return floorplans.map{|floorplan| unit_type_from_floorplan(floorplan)}
      end

      # Return a UnitType record based on the provided Vardi::Voyager::Data::Floorplan
      def unit_type_from_floorplan(floorplan)
        unit_type = UnitType.where(property_id: @property.id, remoteid: floorplan.remoteid).first || UnitType.new
        unit_type.property ||= @property
        unit_type.name = floorplan.name
        unit_type.remoteid = floorplan.remoteid
        unit_type.bathrooms = floorplan.bathrooms
        unit_type.bedrooms = floorplan.bedrooms
        unit_type.market_rent = floorplan.market_rent
        unit_type.sqft = floorplan.sqft

        return unit_type
      end

      # Return Lead records based on the provided [ Vardi::Voyager::Data::GuestCard ]
      def collection_from_guestcards(guestcards)
        return guestcards.map{|guestcard| lead_from_guestcard(guestcard)}
      end

      # Return a Lead record based on the provided Vardi::Voyager::Data::GuestCard
      def lead_from_guestcard(guestcard)
        remoteid = guestcard.prospect_id || guestcard.tenant_id

        lead = Lead.where(property_id: @property.id, remoteid: remoteid).first || Lead.new

        preference = lead.preference || LeadPreference.new

        if lead.new_record?
          lead.remoteid = remoteid
          lead.title = guestcard.name_prefix
          lead.first_name = guestcard.first_name
          lead.middle_name = guestcard.middle_name
          lead.last_name = guestcard.last_name
          unless guestcard.phones.nil?
            lead.phone1 = guestcard.phones.first.try(:last)
            lead.phone2 = guestcard.phones.last.try(:last) if guestcard.phones.size > 1
          end
          lead.email = guestcard.email
          lead.state = lead_state_for(guestcard)
          lead.priority = priority_from_state(lead.state)
          lead.notes = guestcard.summary
          lead.first_comm = DateTime.now
          lead.referral = 'Yardi Voyager'

          preference.move_in = guestcard.expected_move_in || guestcard.actual_move_in
          preference.beds = guestcard.bedrooms
          preference.max_price = guestcard.rent unless guestcard.rent.nil?
          preference.notes = guestcard.preference_comment # Note that Yardi Voyager data in the Comment node is often truncated.
          preference.raw_data = guestcard.summary

          lead.source = @lead_source
          lead.preference = preference
          lead.property = @property
        else
          # Update Lead State from Yardi Data
          # We will not merge changes from Voyager into Druid
          old_state = lead.state
          new_state = lead_state_for(guestcard)

          # Has the Lead state progressed?
          if Lead.compare_states(new_state, old_state) == 1
            event_name = Lead.event_name_for_transition(from: old_state, to: new_state)
            if event_name
              # We want to progress the state even if tasks are incomplete
              lead.ignore_incomplete_tasks = true
              lead.trigger_event(event_name: event_name)
            else
              # no event can transition the Lead
              msg = "Lead Adapter Error! Can't update Lead[#{lead.id}] state for GuestCard[#{guestcard.prospect_id}] for Property[#{@property.name}] with record_type[#{guestcard.record_type}]"
              Rails.logger.warn msg
              if !lead.open?
                # If the Lead is unclaimed, this issue isn't urgent and doesn't require notification.
                # ( We assume that the Lead is unclaimed for a reason )
                ErrorNotification.send(StandardError.new(msg), {lead_id: lead.id, guestcard: guestcard.summary})
              end
            end
          end
        end

				new_comments = notes_from_guestcard_events(lead: lead, events: guestcard.events)
        lead.comments << new_comments

        return lead
      end

      def notes_from_guestcard_events(lead:, events: [])
        return ( events || [] ).map do |event|
          event_type, event_date, event_comment = event
          event_date_parsed = (DateTime.parse(event_date) rescue nil)
					event_lead_action_id = lead_action_from_event_type(event_type).try(:id)
          event_content = event_comment
          if event_date_parsed.nil?
            event_content += " [#{event_date_parsed}]"
          end
					event_user_id = lead.user_id
					old_note = Note.where(lead_action_id: event_lead_action_id,
																notable_id: lead.id, notable_type: 'Lead',
																content: event_content).first
					if old_note
						nil
					else
						Note.new(
							user_id: event_user_id,
							lead_action_id: event_lead_action_id,
							notable_id: lead.id,
							notable_type: 'Lead',
							content: event_content,
              created_at: ( event_date_parsed || DateTime.now )
						)
					end
        end.compact
      end

      def lead_action_from_event_type(event_type)
        action_name = {
            'Application': 'Process Application',
            'ApplicationDenied': 'Process Application',
            'Appointment': 'Schedule Appointment',
            'Approve': 'Process Application',
            'CallFromProspect': 'Make Call',
            'CallToProspect': 'Make Call',
            'Cancel': 'Other',
            'CancelApplication': 'Process Application',
            'CancelAppointment': 'Schedule Appointment',
            'Chat': 'Other',
            'Email': 'Send Email',
            'First Contact': 'First Contact',
            'Hold': 'Other',
            'LeaseSign': 'Process Application',
            'Other': 'Other',
            'ReActivate': 'Other',
            'ReApply': 'Process Application',
            'Release': 'Process Application',
            'ReturnVisit': 'Schedule Appointment',
            'Show': 'Tour Units',
            'Text': 'Send SMS',
            'Transfer': 'Other',
            'WalkIn': 'Process Application',
            'WebService': 'Other' }.
          fetch(event_type, 'Other')
          return LeadAction.where(name: action_name).first || LeadAction.where(name: 'Other').first
      end

      def fetch_GuestCards(propertycode)
        adapter = Yardi::Voyager::Api::GuestCards.new
        adapter.debug = true if debug?
        start_date = @params.fetch(:start_date,nil)
        end_date = @params.fetch(:end_date, DateTime.now)
        return adapter.getGuestCards(propertycode, start_date: start_date, end_date: end_date)
      end

      def fetch_Floorplans(propertycode)
        adapter = Yardi::Voyager::Api::Floorplans.new
        adapter.debug = true if debug?
        return adapter.getFloorPlans(propertycode)
      end

      def fetch_Units(propertycode)
        adapter = Yardi::Voyager::Api::Units.new
        adapter.debug = true if debug?
        return adapter.getUnits(propertycode)
      end

      def send_Leads(leads)
        # Abort if ANY leads belong to the wrong Property
        err = leads.map(&:property_id).compact.uniq.any?{|p_id| p_id != @property.id }
        raise "Leads::Adapters::YardiVoyager Aborting transfer of Leads due to Property assignment mismatch" if err

        adapter = Yardi::Voyager::Api::GuestCards.new
        adapter.debug = true if debug?

        return leads.map do |lead|
          adapter.sendGuestCard(propertyid: @property_code, lead: lead)
        end
      end

      def lead_state_for(guestcard)
        record_type_state_map = {
          'applicant' => 'application',
          'approved_applicant' => 'approved',
          'future_resident' => 'movein',
          'prospect' => 'open' }
        state = record_type_state_map.fetch( guestcard.record_type, 'open' )
        return state
      end

      def priority_from_state(state)
        priority = 'urgent'
        case state
          when 'application'
            priority = 'high'
          when 'approved'
            priority = 'high'
          when 'movein'
            priority = 'high'
          when 'open'
            priority = 'urgent'
          else
            priority = 'urgent'
        end
        return priority
      end

      def get_property_code(params)
        return params[:property_code]
      end

      def get_lead_source
        return LeadSource.active.where(slug: LEAD_SOURCE_SLUG).first
      end

      def property_for_listing_code(listingcode)
        property = @lead_source.listings.active.where(code: listingcode).
          first.try(:property)
        Rails.logger.warn "Error in Leads::Adapters::YardiVoyager finding PropertyListing code '#{listingcode}'" if property.nil?
        return property
      end

      def debug?
        return ENV.fetch('DEBUG', 'true').downcase == 'true'
      end

    end
  end
end
