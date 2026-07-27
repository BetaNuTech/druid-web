module Leads
  # Pushes self-booked tour leads (open, unassigned, flagged with the
  # "Tour Booking detected" system note) to Yardi Voyager as guestcards.
  #
  # These leads are intentionally left open/unassigned for agent pickup,
  # which excludes them from the standard Yardi sync
  # (Properties::YardiVoyager#new_leads_for_sync requires an assigned user).
  # This service runs on a schedule (see lib/tasks/leads.rake
  # leads:push_tour_guestcards) while self-booked tours continue to arrive.
  #
  # Per lead:
  # - Dedup against Yardi by email/phone; link remoteid if a guestcard exists
  # - Force referral/TransactionSource to 'Property Website'
  # - Create the guestcard with a round-robin active Yardi agent and a
  #   FirstContact event carrying the original arrival date and tour details
  # - Leads remain open and unassigned in BlueSky; remoteid prevents re-sync
  class TourGuestcardPusher
    MAX_ATTEMPTS = 3
    RETRY_WAIT = 15 # seconds, multiplied by attempt number
    FORCED_REFERRAL = 'Property Website'.freeze
    TOUR_NOTE_PREFIX = 'Tour Booking detected'.freeze
    # Yardi roster entries that are not human agents. 'Admin' would activate
    # Lea AI; never fall back to it.
    SYSTEM_AGENT_NAMES = ['Portal', 'Admin', 'Lea-Lite', 'Lea-Pro'].freeze
    # Boilerplate segments to strip from preference notes for the Yardi comment
    NOTE_BOILERPLATE = [
      /Lead has consented to receiving text messages\.?/,
      /Processed by AI\.?/
    ].freeze
    COMMENT_LIMIT = 400
    ADVISORY_LOCK_KEY = 'leads_tour_guestcard_pusher'.freeze

    def initialize(dry_run: false)
      @dry_run = dry_run
    end

    # Audit and push for all active properties with a Voyager code.
    # Returns an Array of per-property result Hashes.
    def call
      results = nil
      with_advisory_lock do |acquired|
        unless acquired
          return [{ property: '(all)', skipped: 'another push run is in progress' }]
        end

        results = Property.active.order(:name).map { |property| push_property(property) }
      end
      results
    end

    def push_property(property)
      code = property.voyager_property_code
      return { property: property.name, skipped: 'No Voyager property code' } if code.blank?

      leads = candidate_leads(property)
      return { property: property.name, linked: 0, created: 0, skipped_leads: 0, errors: 0 } if leads.empty?

      agent_names = fetch_active_agents(property, code)
      if agent_names.nil?
        return { property: property.name, error: 'Could not fetch Yardi agents', pending: leads.size }
      end
      if agent_names.empty?
        msg = "Leads::TourGuestcardPusher: no active Yardi agents for #{property.name} (#{code}); " \
              "#{leads.size} tour leads pending"
        Rails.logger.error(msg)
        Note.create(content: msg, classification: :error, notable: property)
        return { property: property.name, error: 'No active Yardi agents in Voyager', pending: leads.size }
      end

      adapter = Leads::Adapters::YardiVoyager.new(property)
      counts = { linked: 0, created: 0, skipped_leads: 0, errors: 0 }
      rr = rand(agent_names.size) # rotate starting agent across runs

      leads.each do |lead|
        result = push_lead(lead, adapter, agent_names[rr % agent_names.size])
        # Advance rotation whenever a create was attempted (not for links/skips)
        rr += 1 unless [:linked, :would_link, :skipped].include?(result)
        case result
        when :linked, :would_link then counts[:linked] += 1
        when :created, :would_create then counts[:created] += 1
        when :skipped then counts[:skipped_leads] += 1
        else counts[:errors] += 1
        end
      end

      { property: property.name, dry_run: @dry_run }.merge(counts)
    end

    private

    def candidate_leads(property)
      tour_lead_ids = Note.where(notable_type: 'Lead')
                          .where('content LIKE ?', "#{TOUR_NOTE_PREFIX}%")
                          .pluck(:notable_id)
      Lead.where(id: tour_lead_ids, property_id: property.id, state: 'open')
          .where(remoteid: [nil, ''])
          .order(:created_at)
          .to_a
    end

    # Returns Array of agent name strings, or nil on persistent API failure
    def fetch_active_agents(property, code)
      attempts = 0
      begin
        attempts += 1
        names = api.getAgents(code)
      rescue StandardError => e
        if attempts < MAX_ATTEMPTS
          sleep(RETRY_WAIT * attempts)
          retry
        end
        msg = "Leads::TourGuestcardPusher failed fetching Yardi agents for #{property.name} (#{code}) " \
              "after #{attempts} attempts: #{e}"
        Rails.logger.error(msg)
        Note.create(content: msg, classification: :error, notable: property)
        return nil
      end
      names - SYSTEM_AGENT_NAMES
    end

    # Returns :linked, :created, :skipped, :error (or :would_link /
    # :would_create in dry-run mode)
    def push_lead(lead, adapter, agent_name)
      # Dedup: search Yardi by email/phone. On search failure, skip the lead
      # entirely (it will be retried next run) rather than risk a duplicate.
      begin
        existing = adapter.findLeadGuestCard(lead)
      rescue StandardError => e
        Rails.logger.warn("Leads::TourGuestcardPusher: Yardi search failed for Lead[#{lead.id}]; " \
                          "skipping this run. #{e}")
        return :skipped
      end

      if existing&.prospect_id.present?
        return :would_link if @dry_run

        lead.update_columns(remoteid: existing.prospect_id, updated_at: Time.current)
        Note.create(notable: lead, classification: 'system',
                    content: "Linked to existing Yardi guestcard #{existing.prospect_id} " \
                             '(self-booked tour push; not re-created)')
        return :linked
      end

      return :would_create if @dry_run

      if lead.referral != FORCED_REFERRAL
        original_referral = lead.referral
        lead.update_columns(referral: FORCED_REFERRAL)
        Note.create(notable: lead, classification: 'system',
                    content: "Referral changed from #{original_referral.inspect} to " \
                             "'#{FORCED_REFERRAL}' (self-booked tour push)")
      end

      Leads::NameParser.fix_and_save!(lead) && lead.reload

      first_name, last_name = split_agent_name(agent_name)
      agent = User.new(profile: UserProfile.new(first_name: first_name, last_name: last_name))
      updated = api.sendGuestCard(lead: lead, include_events: true, agent: agent,
                                  first_contact_comment: tour_comment(lead))

      if updated&.remoteid.present?
        lead.update_columns(remoteid: updated.remoteid, updated_at: Time.current)
        Note.create(notable: lead, classification: 'system',
                    content: "Pushed to Yardi as guestcard #{updated.remoteid} (self-booked tour push; agent #{agent_name})")
        :created
      else
        Rails.logger.error("Leads::TourGuestcardPusher: no remoteid returned for Lead[#{lead.id}]")
        :error
      end
    rescue StandardError => e
      Rails.logger.error("Leads::TourGuestcardPusher: error pushing Lead[#{lead.id}]: #{e}")
      Note.create(notable: lead, classification: :error,
                  content: "Self-booked tour push failed: #{e.to_s.truncate(300)}")
      :error
    end

    def tour_comment(lead)
      details = lead.preference&.notes.to_s.dup
      NOTE_BOILERPLATE.each { |re| details.gsub!(re, '') }
      details = details.split(/\n+/).map(&:strip).reject(&:blank?).join(' | ')
      ['Self-booked tour lead.', details.presence].compact.join(' ').truncate(COMMENT_LIMIT)
    end

    def split_agent_name(name)
      parts = name.to_s.split(' ', 2)
      [parts[0], parts[1] || '']
    end

    def with_advisory_lock
      lock_id = Zlib.crc32(ADVISORY_LOCK_KEY)
      acquired = ActiveRecord::Base.connection.select_value("SELECT pg_try_advisory_lock(#{lock_id})")
      acquired = ActiveModel::Type::Boolean.new.cast(acquired)
      yield acquired
    ensure
      ActiveRecord::Base.connection.execute("SELECT pg_advisory_unlock(#{lock_id})") if acquired
    end

    def api
      @api ||= Yardi::Voyager::Api::GuestCards.new
    end
  end
end
