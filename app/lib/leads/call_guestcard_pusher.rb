module Leads
  # Pushes BlueConnect call leads (LeadSource 'CallCenter') to Yardi Voyager
  # as guest cards assigned to the 'Admin' agent, so Lea AI picks them up -
  # unless the caller already has a guest card at that property.
  #
  # Off unless CALL_LEAD_GUESTCARD_PUSH_ENABLED=true. While on, call leads are
  # queued on create (Leads::CallGuestcards), Bluesky sends callers no
  # automated messages, and this service resolves the queue every 10 minutes
  # (rake leads:push_call_guestcards, run at the end of leads:yardi:send_guestcards).
  #
  # Each queued lead ends as one CallGuestcardPush status:
  #   created              no card anywhere: new card, agent Admin
  #   linked_new_card      a card was made for this call (usually Lea AI's); its
  #                        source is corrected if CALL_LEAD_GUESTCARD_FIX_SOURCE_ENABLED
  #   linked_existing_card the caller already had a card; left untouched
  #   repeat_call          same caller resolved here within 48h: invalidated as a duplicate
  #   duplicate_lead       another lead at the property already links the caller's
  #                        card: invalidated as a duplicate
  #   resident             caller is a current Yardi resident: invalidated as a resident
  # Created and linked leads are assigned to the system user and moved to
  # prospect, as Lea AI email leads are.
  #
  # Duplicate checks read the Yardi backup database (Yardi::Backup::Database):
  # Voyager's SOAP search misses most existing cards. The backup trails Yardi
  # by 30-60 minutes, so a lead is only resolved once the backup is newer than
  # the call plus the hold time - any card Lea AI made while answering the
  # call is visible by then. Cards this service made are matched from
  # Bluesky's own records until the backup catches up.
  #
  # See doc/call_lead_guestcard_push.md.
  class CallGuestcardPusher
    class Error < StandardError; end

    ENABLED_ENV = 'CALL_LEAD_GUESTCARD_PUSH_ENABLED'.freeze
    FIX_SOURCE_ENV = 'CALL_LEAD_GUESTCARD_FIX_SOURCE_ENABLED'.freeze
    HOLD_MINUTES_ENV = 'CALL_LEAD_GUESTCARD_HOLD_MINUTES'.freeze
    DEFAULT_HOLD_MINUTES = 15
    ADMIN_AGENT_NAME = 'Admin'.freeze
    # Lea AI creates its card while the call is in progress, which can be
    # before Bluesky's lead exists: a card this close to the lead is the call's own.
    SAME_CALL_WINDOW = 30.minutes
    # A card created later than this after the call came from something else
    # (an online application, an agent). Live calls are decided within ~75
    # minutes; this matters for backfilled calls (Leads::CallGuestcardBackfill).
    SAME_CALL_LOOKAHEAD = 2.hours
    # Mirrors Leads::Duplicates RECENT
    REPEAT_CALL_WINDOW = 48.hours
    MAX_ATTEMPTS = 5
    MAX_LEADS_PER_RUN = 100
    STALE_BACKUP_AFTER = 3.hours
    ADVISORY_LOCK_KEY = 'leads_call_guestcard_pusher'.freeze
    DECISION_STATUSES = {
      repeat_call: CallGuestcardPush::REPEAT_CALL,
      resident: CallGuestcardPush::RESIDENT,
      link_new_card: CallGuestcardPush::LINKED_NEW_CARD,
      link_existing_card: CallGuestcardPush::LINKED_EXISTING_CARD,
      create: CallGuestcardPush::CREATED
    }.freeze

    def self.enabled?(env = ENV)
      env[ENABLED_ENV].to_s.strip.casecmp?('true')
    end

    def self.fix_source_enabled?(env = ENV)
      env[FIX_SOURCE_ENV].to_s.strip.casecmp?('true')
    end

    def self.hold(env = ENV)
      minutes = Integer(env[HOLD_MINUTES_ENV].presence || DEFAULT_HOLD_MINUTES, exception: false)
      (minutes.nil? || minutes.negative? ? DEFAULT_HOLD_MINUTES : minutes).minutes
    end

    # How a queued call resolves, given what Yardi and Bluesky know. `cards`
    # are Yardi::Backup::Database::Prospect rows matching the caller's phone.
    # Returns [decision, card]: decision is :repeat_call, :resident,
    # :link_new_card, :link_existing_card or :create.
    def self.decide(called_at:, cards:, resident:, prior_prospect_id: nil)
      return [:repeat_call, nil] if prior_prospect_id.present?
      return [:resident, nil] if resident
      return [:create, nil] if cards.empty?

      same_call = cards.select do |card|
        card.created_at&.between?(called_at - SAME_CALL_WINDOW, called_at + SAME_CALL_LOOKAHEAD)
      end
      if same_call.any?
        [:link_new_card, same_call.min_by { |card| [card.primary? ? 0 : 1, card.created_at] }]
      else
        [:link_existing_card, cards.max_by { |card| [card.primary? ? 1 : 0, card.created_at || Time.zone.at(0)] }]
      end
    end

    def initialize(dry_run: false, database: Yardi::Backup::Database, api: nil, now: Time.current)
      @dry_run = dry_run
      @database = database
      @api = api
      @now = now
      @hold = self.class.hold
      @fix_source = self.class.fix_source_enabled?
    end

    # Resolves every queued lead the backup covers. Returns a summary Hash.
    def call
      summary = nil
      with_advisory_lock do |acquired|
        return { skipped: 'another call guest card push is in progress' } unless acquired

        summary = run
      end
      summary
    end

    # One-lead attribution correction, independent of FIX_SOURCE_ENV
    # (rake leads:call_guestcards:fix_source[LEAD_ID]). Returns the status.
    def fix_source_for(push)
      raise Error, "Lead #{push.lead_id} is not linked to a Yardi guest card" if push.yardi_prospect_id.blank?

      @database.open do |db|
        card = db.prospect(push.property.voyager_property_code, push.yardi_prospect_id)
        raise Error, "Guest card #{push.yardi_prospect_id} not found in the Yardi backup" if card.nil?

        status = correct_source(push, card, db: db, force: true)
        push.update!(source_fix_status: status, yardi_source: card.source) unless @dry_run
        status
      end
    end

    private

    def run
      queue = CallGuestcardPush.pending.joins(:lead).includes(:property, lead: :property)
                               .where('leads.created_at <= ?', @now - @hold)
                               .order('leads.created_at').limit(MAX_LEADS_PER_RUN).to_a
      summary = { dry_run: @dry_run, queued: queue.size, waiting: 0, outcomes: Hash.new(0) }
      return summary if queue.empty?

      @database.open do |db|
        as_of = db.data_as_of
        raise Error, 'Yardi backup database reported no data time' if as_of.nil?

        summary[:backup_as_of] = as_of
        check_backup_freshness(as_of)
        ready, waiting = queue.partition { |push| covered?(push, as_of) }
        summary[:waiting] = waiting.size

        ready.group_by(&:property).each do |property, pushes|
          code = property.voyager_property_code
          if code.blank?
            summary[:waiting] += pushes.size
            next
          end

          phones = pushes.filter_map(&:phone).uniq
          cards = db.prospects_by_phone(code, phones)
          residents = db.resident_phones(code, phones)
          pushes.each do |push|
            outcome = resolve(push, cards: cards.fetch(push.phone, []), resident: residents.include?(push.phone), db: db)
            summary[:outcomes][outcome] += 1
          end
        end
      end
      summary
    rescue Yardi::Backup::Database::Error, Error => e
      Rails.logger.error("Leads::CallGuestcardPusher: #{e.message}; queued call leads stay pending")
      ErrorNotification.send(e)
      (summary || {}).merge(error: e.message)
    end

    # Resolve only once the backup reflects the call plus the hold time, and
    # (after a failed attempt) the attempt itself - so a card a failed push
    # may still have created is seen before trying again.
    def covered?(push, as_of)
      push.lead.created_at + @hold <= as_of && (push.attempts.zero? || push.updated_at <= as_of)
    end

    def resolve(push, cards:, resident:, db:)
      lead = push.lead
      return finish(push, CallGuestcardPush::SKIPPED_NOT_OPEN) unless lead.open?
      return finish(push, CallGuestcardPush::SKIPPED_NO_PHONE) if push.phone.blank?
      # A card was created on an earlier attempt but the lead was not updated
      if push.yardi_prospect_id.present?
        return @dry_run ? CallGuestcardPush::CREATED : adopt_created(push, push.yardi_prospect_id)
      end

      prior_prospect_id = prior_prospect_id_for(push)
      decision, card = self.class.decide(called_at: lead.created_at, cards: cards, resident: resident,
                                         prior_prospect_id: prior_prospect_id)
      return DECISION_STATUSES.fetch(decision) if @dry_run

      case decision
      when :repeat_call
        invalidate(lead, :duplicate, "Repeat call: the caller is already in Yardi as guest card #{prior_prospect_id}")
        finish(push, CallGuestcardPush::REPEAT_CALL, yardi_prospect_id: prior_prospect_id)
      when :resident
        invalidate(lead, :resident, 'Caller is a current resident in Yardi')
        finish(push, CallGuestcardPush::RESIDENT)
      when :link_new_card, :link_existing_card
        link(push, card, decision == :link_new_card ? CallGuestcardPush::LINKED_NEW_CARD : CallGuestcardPush::LINKED_EXISTING_CARD, db)
      else
        create_card(push)
      end
    rescue StandardError => e
      record_failure(push, e)
    end

    # Another call lead from this caller at this property, resolved to a
    # guest card within REPEAT_CALL_WINDOW before this one.
    def prior_prospect_id_for(push)
      created_at = push.lead.created_at
      CallGuestcardPush.joins(:lead)
                       .where(property_id: push.property_id, phone: push.phone)
                       .where.not(id: push.id).where.not(yardi_prospect_id: [nil, ''])
                       .where.not(status: CallGuestcardPush::PENDING)
                       .where('leads.created_at BETWEEN ? AND ?', created_at - REPEAT_CALL_WINDOW, created_at)
                       .order('leads.created_at').pick(:yardi_prospect_id)
    end

    def link(push, card, status, db)
      holder = remoteid_holder(push.lead, card.prospect_id)
      if holder&.property_id == push.property_id
        # The caller called again: another lead here already links their card
        invalidate(push.lead, :duplicate, "Duplicate of Lead #{holder.id}, already linked to Yardi guest card #{card.prospect_id}")
        return finish(push, CallGuestcardPush::DUPLICATE_LEAD, yardi_prospect_id: card.prospect_id, yardi_source: card.source)
      end

      adopt(push.lead, card.prospect_id,
            "Matched to existing Yardi guest card #{card.prospect_id} (created by #{card.created_by.presence || 'unknown'}, " \
            "agent #{card.agent.presence || 'none'}); not re-created",
            store_remoteid: holder.nil?)
      source_fix = status == CallGuestcardPush::LINKED_NEW_CARD ? correct_source(push, card, db: db) : nil
      finish(push, status, yardi_prospect_id: card.prospect_id, yardi_source: card.source, source_fix_status: source_fix)
    end

    # Another lead at the same property already carrying this Yardi ID, if
    # any (Lead remoteids are unique per property).
    def remoteid_holder(lead, prospect_id)
      Lead.where(remoteid: prospect_id, property_id: lead.property_id).where.not(id: lead.id).first
    end

    def create_card(push)
      lead = push.lead
      # Fix "LAST,FIRST" or missing names in memory only: saving here would
      # re-run duplicate detection before the lead is assigned. #adopt saves.
      names = Leads::NameParser.parse_and_fix(lead)
      lead.assign_attributes(first_name: names[:first_name], last_name: names[:last_name]) if names[:changed]

      sent = api.sendGuestCard(lead: lead, include_events: true, agent: admin_agent,
                               first_contact_comment: call_comment(lead))
      prospect_id = sent&.remoteid
      raise Error, 'Yardi did not return a guest card id' if prospect_id.blank?

      # Record the card before touching the lead, so a retry never re-creates it
      push.update!(yardi_prospect_id: prospect_id)
      adopt_created(push, prospect_id)
    end

    def adopt_created(push, prospect_id)
      adopt(push.lead, prospect_id,
            "Pushed to Yardi as guest card #{prospect_id} (agent #{ADMIN_AGENT_NAME} for Lea AI, " \
            "source #{push.lead.referral.presence || 'Bluesky'})",
            store_remoteid: remoteid_holder(push.lead, prospect_id).nil?)
      finish(push, CallGuestcardPush::CREATED, yardi_prospect_id: prospect_id)
    end

    # Link the lead to its card and hand it to the system user as a prospect,
    # the same as Lea AI email leads (Leads::Messaging is gated, so no texts).
    def adopt(lead, prospect_id, note, store_remoteid: true)
      if store_remoteid
        lead.remoteid = prospect_id
      else
        # sendGuestCard set it in memory; another lead here already has it
        lead.remoteid = lead.remoteid_in_database
        note += ". Yardi reuses #{prospect_id} for another guest card at this property, so it is kept on the queue entry, not the lead"
      end
      unless lead.trigger_event(event_name: 'work', user: User.system)
        raise Error, "could not move Lead[#{lead.id}] to prospect: #{lead.errors.full_messages.to_sentence.presence || lead.state}"
      end

      Note.create!(notable: lead, classification: 'system', content: "Call lead push: #{note}")
    end

    def invalidate(lead, classification, memo)
      lead.classification = classification
      lead.transition_memo = "Call lead push: #{memo}"
      return if lead.trigger_event(event_name: 'invalidate', user: User.system)

      raise Error, "could not invalidate Lead[#{lead.id}]: #{lead.errors.full_messages.to_sentence.presence || lead.state}"
    end

    # Ask Yardi to replace the source on a card made for this call (Lea AI
    # records every call as 'Property Website'). Returns the source_fix_status,
    # or nil when correction is switched off.
    def correct_source(push, card, db:, force: false)
      referral = push.referral.to_s.strip
      return 'not_needed' if referral.blank? || card.source.to_s.strip.casecmp?(referral)
      return nil unless @fix_source || force
      # Re-stating anything but an active prospect could reopen a canceled card
      return 'skipped_status' unless card.status.to_s.strip.casecmp?('Prospect')
      # An update could land on the other card that shares the ID
      return 'skipped_shared_id' if db.prospect_id_shared?(card.prospect_id)

      # The source is changed by re-stating the card's one first-contact event
      code = push.property.voyager_property_code
      events = db.first_contact_events(code, card.prospect_id)
      return 'skipped_no_first_contact' unless events.size == 1
      return 'would_send' if @dry_run

      returned = api.sendSourceCorrection(propertyid: code, prospect: card, event: events.first, source: referral)
      Note.create!(notable: push.lead, classification: 'system',
                   content: "Call lead push: asked Yardi to change guest card #{card.prospect_id}'s source " \
                            "from #{card.source.inspect} to #{referral.inspect} (first-contact event " \
                            "#{events.first.event_id.to_i}; agent left as #{card.agent.inspect})")
      returned == card.prospect_id ? 'sent' : "unexpected_response:#{returned}"
    rescue StandardError => e
      Rails.logger.error("Leads::CallGuestcardPusher: source correction for #{card.prospect_id} failed: #{e.message}")
      'failed'
    end

    def finish(push, status, **attributes)
      push.update!(status: status, resolved_at: Time.current, last_error: nil, **attributes) unless @dry_run
      status
    end

    def record_failure(push, error)
      Rails.logger.error("Leads::CallGuestcardPusher: Lead[#{push.lead_id}] #{error.class}: #{error.message}")
      return 'error' if @dry_run

      attempts = push.attempts + 1
      status = attempts >= MAX_ATTEMPTS ? CallGuestcardPush::FAILED : CallGuestcardPush::PENDING
      push.update!(attempts: attempts, status: status, last_error: "#{error.class}: #{error.message}".truncate(1_000))
      if status == CallGuestcardPush::FAILED
        Note.create(notable: push.lead, classification: :error,
                    content: "Call lead push gave up after #{attempts} attempts: #{error.message.truncate(300)}")
      end
      status == CallGuestcardPush::FAILED ? CallGuestcardPush::FAILED : 'retry'
    end

    def check_backup_freshness(as_of)
      return if @now - as_of <= STALE_BACKUP_AFTER

      msg = "Yardi backup database is #{((@now - as_of) / 1.hour).round(1)}h behind (data as of " \
            "#{as_of.utc.iso8601}); queued call leads wait until it catches up"
      Rails.logger.error("Leads::CallGuestcardPusher: #{msg}")
      ErrorNotification.send(StandardError.new(msg), { as_of: as_of.utc.iso8601 })
    end

    def call_comment(lead)
      called_at = lead.created_at.in_time_zone(lead.property&.timezone.presence || 'UTC')
      "Inbound call via the #{lead.referral.presence || 'property'} tracking number at " \
        "#{called_at.strftime('%-m/%-d/%Y %-l:%M %p %Z')} (BlueConnect). Created by Bluesky for Lea AI follow-up."
    end

    def admin_agent
      User.new(profile: UserProfile.new(first_name: ADMIN_AGENT_NAME, last_name: ''))
    end

    def api
      @api ||= Yardi::Voyager::Api::GuestCards.new
    end

    def with_advisory_lock
      lock_id = Zlib.crc32(ADVISORY_LOCK_KEY)
      acquired = ActiveRecord::Base.connection.select_value("SELECT pg_try_advisory_lock(#{lock_id})")
      acquired = ActiveModel::Type::Boolean.new.cast(acquired)
      yield acquired
    ensure
      ActiveRecord::Base.connection.execute("SELECT pg_advisory_unlock(#{lock_id})") if acquired
    end
  end
end
