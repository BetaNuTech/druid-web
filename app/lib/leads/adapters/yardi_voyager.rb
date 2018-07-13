module Leads
  module Adapters
    class YardiVoyager
      LEAD_SOURCE_SLUG = 'YardiVoyager'
      DEFAULT_RENTAL_TYPE = 'Residential'

      # Accepts a Hash
      #
      # Ex: { property_code: 'marble'}
      def initialize(params)
        @lead_source =  get_lead_source
        if @lead_source.nil?
          msg = "Lead Adapter Error! LeadSource record for #{LEAD_SOURCE_SLUG} is missing!"
          err = StandardError.new(msg)
          ErrorNotification.send(err, params)
          Rails.logger.error msg
          raise err
        end
        @property_code = get_property_code(params)
        @property = property_for_listing_code(@property_code)
      end

      def processLeads
        @data = fetch_GuestCards(@property_code)
        leads = collection_from_guestcards(@data)
        ActiveRecord::Base.transaction do
          leads.each{|l| l.save}
        end
        return leads
      end

      def processUnitTypes
        @data = fetch_Floorplans(@property_code)
        unit_types = collection_from_floorplans(@data)
        ActiveRecord::Base.transaction do
          unit_types.each{|l| l.save}
        end
        return unit_types
      end

      def processUnits
        @data = fetch_Units(@property_code)
        units = collection_from_yardi_units(@data)
        ActiveRecord::Base.transaction do
          units.each{|l| l.save}
        end
        return units
      end

      # Send new/unsynced Leads to Yardi Voyager
      def sendLeads(leads)
        updated_leads = send_Leads(leads)
        ActiveRecord::Base.transaction do
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

      def collection_from_guestcards(guestcards)
        return guestcards.map{|guestcard| lead_from_guestcard(guestcard)}
      end

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

          preference.move_in = guestcard.expected_move_in || guestcard.actual_move_in
          preference.beds = guestcard.bedrooms
          preference.max_price = guestcard.rent unless guestcard.rent.nil?
          preference.notes = guestcard.preference_comment
          preference.raw_data = guestcard.summary

          lead.source = @lead_source
          lead.preference = preference
          lead.property = @property
        else
          # TODO Update Lead from Yardi Data
          old_state = lead.state
          new_state = lead_state_for(guestcard)

          if compare_states(new_state, old_state) == 1
            event_name = Lead.event_name_for_transition(from: old_state, to: new_state)
            if event_name
              lead.trigger_event(event_name: event_name)
            else
              # no event can transition the Lead
              msg = "Lead Adapter Error! Can't update Lead[#{lead.id}] state for GuestCard[#{guestcard.prospect_id}] for Property[#{@property.name}] with record_type[#{guestcard.record_type}]"
              Rails.logger.warn msg
              ErrorNotification.send(StandardError.new(msg), {lead_id: lead.id, guestcard: guestcard.summary})
            end
          end
        end


        # TODO: Lead Events
        #

        return lead
      end

      def fetch_GuestCards(propertycode)
        adapter = Yardi::Voyager::Api::GuestCards.new
        adapter.debug = true if debug?
        return adapter.getGuestCards(propertycode)
      end

      def fetch_Floorplans(propertycode)
        adapter = Yardi::Voyagee::Api::Floorplans.new
        adapter.debug = true if debug?
        return adapter.getFloorPlans(propertycode)
      end

      def fetch_Units(propertycode)
        adapter = Yardi::Voyager::Api::Units.new
        adapter.debug if debug?
        return adapter.getUnits(propertycode)
      end

      def send_Leads(leads)
        # Abort if ANY leads belong to the wrong Property
        err = leads.map(&:property_id).compact.uniq.any?{|p_id| p_id != @property.id }
        raise "Leads::Adapters::YardiVoyager Aborting transfer of Leads due to Property assignment mismatch" if err

        return leads.map do |lead|
          adapter = Yardi::Voyager::Api::GuestCards.new
          adapter.debug = true if debug?
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
