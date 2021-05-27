module Leads
  module Adapters
    class YardiVoyager
      LEAD_SOURCE_SLUG = 'YardiVoyager'
      DEFAULT_RENTAL_TYPE = 'Residential'

      attr_reader :property, :property_code, :lead_source, :data, :params
      attr_accessor :commit

      # Returns all active Property ID's defined as PropertyListings in the database
      #
      # Returns:
      # [ { name: 'Property Name', code: 'voyagerpropertyid', property: #<Property> } ... ]
      def self.property_codes
        PropertyListing.
            includes(:source, :property).
            active.
            where(properties: {active: true}, lead_sources: {slug: LEAD_SOURCE_SLUG}).
          map do |pl|
            {name: pl.property.name, code: pl.code, property: pl.property}
          end
      end

      def self.property_code(property=nil)
        return nil unless property.present?
        PropertyListing.includes(:source).
            active.
            where(property_id: property.id, lead_sources: {slug: LEAD_SOURCE_SLUG}).
            first&.code
      end

      def self.property(propertyid)
        PropertyListing.where(code: propertyid).first&.property
      end

      # This Class interacts with the YardiVoyager API in the Yardi::Voyager namespace
      # Use it to send Leads to YardiVoyager, or download Leads,
      # Residents, UnitTypes (floorplans), and Units
      #
      # Provide a Property record
      def initialize(property)
        @commit = true
        @property = property
        @lead_source =  get_lead_source
        if @lead_source.nil?
          msg = "Lead Adapter Error! LeadSource record for #{LEAD_SOURCE_SLUG} is missing!"
          err = StandardError.new(msg)
          ErrorNotification.send(err)
          Rails.logger.error msg
          raise err
        end
        @property_code = YardiVoyager.property_code(@property)
      end

      # Fetch New Leads from YardiVoyager
      # or progress Lead state if the Lead is already in BlueSky
      def processLeads(start_date: nil, end_date: DateTime.now)
        @data ||= fetch_GuestCards(start_date: start_date, end_date: end_date, filter: false)
        leads = []
        ActiveRecord::Base.transaction do
          leads = lead_collection_from_guestcards(@data)
          if commit
            leads.each do |lead|
              # Skip dedupe on Voyager Sync to prevent an avalanche of dedupe background jobs
              lead.skip_dedupe = true
              lead.save
            end
          end
        end
        return leads
      end

      # Fetch Residents from YardiVoyager
      def processResidents(start_date: nil, end_date: DateTime.now)
        @data ||= fetch_GuestCards(start_date: start_date, end_date: end_date)
        residents = []
        ActiveRecord::Base.transaction do
          residents = resident_collection_from_guestcards(@data)
          residents.map(&:save) if commit
        end
        return residents
      end

      # Fetch New UnitTypes from YardiVoyager
      def processUnitTypes
        @data = fetch_Floorplans
        unit_types = []
        ActiveRecord::Base.transaction do
          unit_types = collection_from_floorplans(@data)
          unit_types.each{|l| l.save} if commit
        end
        return unit_types
      end

      # Fetch New Units from YardiVoyager
      def processUnits
        @data = fetch_Units
        units = []
        ActiveRecord::Base.transaction do
          units = collection_from_yardi_units(@data)
          units.each{|l| l.save} if commit
        end
        return units
      end

      # Send Leads to Yardi Voyager for GuestCard creation or update
      def sendLeads(leads)
        updated_leads = []
        ActiveRecord::Base.transaction do
          updated_leads = send_Leads(leads)
          updated_leads.each{|l| l.save } if commit
        end
        return updated_leads
      end

      def getGuestCards(start_date: nil, end_date: DateTime.now, filter: false, debug: false)
        adapter = Yardi::Voyager::Api::GuestCards.new
        adapter.debug = debug
        return adapter.
          getGuestCards(@property_code, start_date: start_date, end_date: end_date, filter: filter)
      end

      def findLeadGuestCard(lead, debug: false)
        adapter = Yardi::Voyager::Api::GuestCards.new
        adapter.debug = debug
        params = {}
        if lead.remoteid.present?
          params[:third_party_id] = lead.remoteid
        elsif lead.email.present?
          params[:email_address] = lead.email
        elsif ( leadphone = [ lead.phone1, lead.phone2 ].compact.first ).present?
          params[:phone_number] = leadphone
        else
          params[:first_name] = lead.first_name if lead.first_name.present?
          params[:last_name] = lead.last_name if lead.last_name.present?
        end
        return adapter.getGuestCard(@property_code, params: params)&.first
      end

      def createGuestCards(start_date: 1.day.ago)
        return sendLeads(@property.new_leads_for_sync.where(created_at: start_date..DateTime.now))
      end

      def updateGuestCards(start_date: 1.day.ago)
        return sendLeads(@property.leads_for_sync.where(updated_at: start_date..DateTime.now))
      end

      def cancelGuestCards(start_date: 1.day.ago)
        return sendLeads(@property.leads_for_cancelling.where(updated_at: start_date..DateTime.now))
      end

      def fetch_GuestCards(start_date: nil, end_date: DateTime.now, filter: false)
        adapter = Yardi::Voyager::Api::GuestCards.new
        adapter.debug = true if debug?
        return adapter.getGuestCards(@property_code, start_date: start_date, end_date: end_date, filter: filter)
      end

      def fetch_Floorplans
        adapter = Yardi::Voyager::Api::Floorplans.new
        adapter.debug = true if debug?
        return adapter.getFloorPlans(@property_code)
      end

      def fetch_Units
        adapter = Yardi::Voyager::Api::Units.new
        adapter.debug = true if debug?
        return adapter.getUnits(@property_code)
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
        unit.model = yardi_unit.model

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
      def lead_collection_from_guestcards(guestcards)
        return guestcards.
          select{|g| Yardi::Voyager::Data::GuestCard::ACCEPTED_CUSTOMER_TYPES.include?(g.record_type) }.
          map{|guestcard| lead_from_guestcard(guestcard)}
      end

      def resident_collection_from_guestcards(guestcards)
        return guestcards.
          select{|g| Yardi::Voyager::Data::GuestCard::RESIDENT_TYPES.include?(g.record_type) }.
          map{|guestcard| resident_from_guestcard(guestcard)}
      end

      # Return a Lead record based on the provided Vardi::Voyager::Data::GuestCard
      def lead_from_guestcard(guestcard)
        data_sync_reason = Reason.where(name: 'Data Sync').last
        data_sync_action = LeadAction.where(name: 'Sync from Remote').last

        remoteid = guestcard.prospect_id || guestcard.tenant_id

        lead = Lead.where(property_id: @property.id, remoteid: remoteid).first || Lead.new

        preference = lead.preference || LeadPreference.new

        if lead.new_record?
          lead.remoteid = remoteid
          lead.first_comm = guestcard.first_comm
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
          lead.referral = guestcard.referral || 'Yardi Voyager'

          preference.move_in = guestcard.expected_move_in || guestcard.actual_move_in
          if preference.move_in.present? && preference.move_in < 100.years.ago
            # Guard against invalid data
            preference.move_in = nil
          end

          preference.beds = guestcard.bedrooms
          preference.max_price = guestcard.rent unless guestcard.rent.nil?
          preference.notes = guestcard.preference_comment # Note that Yardi Voyager data in the Comment node is often truncated.
          preference.raw_data = guestcard.summary

          lead.source = @lead_source
          lead.preference = preference
          lead.property = @property
        else
          # Set first_comm if it was not set before
          if guestcard.first_comm.present? &&
              lead.first_comm.to_date == lead.created_at.to_date
            lead.first_comm = guestcard.first_comm
            lead.save if commit
          end

          # Update Lead State from Yardi Data
          # We will not merge changes from Voyager into Bluesky
          old_state = lead.state
          new_state = lead_state_for(guestcard)

          # Has the Lead state progressed?
          if commit && Lead.compare_states(new_state, old_state) == 1
            event_name = Lead.event_name_for_transition(from: old_state, to: new_state)
            if event_name
              # We want to progress the state even if tasks are incomplete
              lead.ignore_incomplete_tasks = true
              lead.skip_event_notifications = true
              lead.trigger_event(event_name: event_name)
              Note.create( # create_event_note
                classification: 'external',
                notable: lead,
                content: 'Lead state updated from Voyager',
                reason: data_sync_reason,
                lead_action: data_sync_action
              )
            else
              # no event can transition the Lead
              msg = "Lead Adapter Error! Can't update Lead[#{lead.id}] state for GuestCard[#{guestcard.prospect_id}] for Property[#{@property.name}] with record_type[#{guestcard.record_type}]"
              Rails.logger.warn msg
              if !lead.open?
                # If the Lead is unclaimed, this issue isn't urgent and doesn't require notification.
                # ( We assume that the Lead is unclaimed for a reason )
                ErrorNotification.send(StandardError.new(msg), {lead_id: lead.id, guestcard: guestcard.summary})
                Note.create( # create_event_note
                  classification: 'error',
                  notable: lead,
                  content: msg,
                  reason: data_sync_reason,
                  lead_action: data_sync_action
                )
              end
            end
          end
        end

        if commit
          new_comments = notes_from_guestcard_events(lead: lead, events: guestcard.events)
          lead.comments << new_comments
        end

        return lead
      end

      def resident_from_guestcard(guestcard)
        remoteid = guestcard.tenant_id || guestcard.prospect_id
        resident = Resident.where(property_id: @property.id, residentid: remoteid).first || Resident.new
        unit = @property.housing_units.where(unit: guestcard.unit).first
        status = case guestcard.record_type
                 when 'former_resident'
                  'former'
                 else
                   'current'
                 end

        resident.property = @property
        resident.unit = unit if unit.present?
        resident.residentid = remoteid
        resident.status = status
        resident.title = guestcard.name_prefix
        resident.first_name = guestcard.first_name
        resident.middle_name = guestcard.middle_name
        resident.last_name = guestcard.last_name

        resident.detail ||= ResidentDetail.new
        resident.detail.email = guestcard.email
        unless guestcard.phones.nil?
          resident.detail.phone1 = guestcard.phones.first.try(:last)
          resident.detail.phone2 = guestcard.phones.last.try(:last) if guestcard.phones.size > 1
        end

        return resident
      end

      def notes_from_guestcard_events(lead:, events: [])
        return ( events || [] ).map do |event|
          event_date_parsed = (DateTime.parse(event.date) rescue nil)
					event_lead_action_id = lead_action_from_event_type(event.event_type).try(:id)
          event_content = event.comments
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
              created_at: ( event_date_parsed || DateTime.now ),
              classification: 'system'
						)
					end
        end.compact
      end


      def lead_action_from_event_type(event_type)
        @lead_action_cache ||= LeadAction.all.to_a
        @other_lead_action ||= @lead_action_cache.select{|la| la.name == 'Other'}.first
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
          lead_action = @lead_action_cache.select{|la| la.name == action_name}.first || @other_lead_action
          return lead_action
      end


      def send_Leads(leads)
        # Abort if ANY leads belong to the wrong Property
        err = leads.map(&:property_id).compact.uniq.any?{|p_id| p_id != @property.id }
        raise "Leads::Adapters::YardiVoyager Aborting transfer of Leads due to Property assignment mismatch" if err

        adapter = Yardi::Voyager::Api::GuestCards.new
        adapter.debug = true if debug?

        return leads.map do |lead|
          adapter.sendGuestCard(lead: lead, include_events: true)
        end
      end

      def lead_state_for(guestcard)
        record_type_state_map = {
          'applicant' => 'application',
          'approved_applicant' => 'approved',
          'canceled' => 'disqualified',
          'current_resident' => 'resident',
          'denied_applicant' => 'denied',
          'former_resident' => 'exresident',
          'future_resident' => 'approved',
          'guarantor' => 'open',
          'other' => 'open',
          'prospect' => 'open',
          'roommate' => 'open',
          'spouse' => 'open'
        }
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
          when 'open'
            priority = 'urgent'
          when 'disqualified'
            priority = 'zero'
          else
            priority = 'urgent'
        end
        return priority
      end

      def get_lead_source
        return LeadSource.active.where(slug: LEAD_SOURCE_SLUG).first
      end

      def debug?
        return ENV.fetch('DEBUG', 'true').downcase == 'true'
      end

    end
  end
end
