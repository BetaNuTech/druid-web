module Leads
  # Queues BlueConnect call leads from before the call lead push went live, so
  # Leads::CallGuestcardPusher resolves them exactly like new calls: an Admin
  # guest card when the caller has none, a link when they do, or closing the
  # lead as a repeat call or resident.
  #
  # Only open leads with no queue entry are taken, so it is safe to run twice.
  # A dry run simulates the pusher's decisions against the Yardi backup
  # (including repeat-call chains) and changes nothing.
  #
  #   rake leads:call_guestcards:backfill DAYS=30 DRY_RUN=true
  #
  # See doc/call_lead_guestcard_push.md.
  class CallGuestcardBackfill
    DEFAULT_DAYS = 30
    PHONE_BATCH = 100
    AGE_BUCKETS = { '0-7 days' => 0..7, '8-14 days' => 8..14, '15-21 days' => 15..21, '22-30+ days' => 22..Float::INFINITY }.freeze

    def initialize(days: DEFAULT_DAYS, dry_run: true, database: Yardi::Backup::Database, now: Time.current)
      @days = days
      @dry_run = dry_run
      @database = database
      @now = now
    end

    def candidates
      call_center = LeadSource.find_by(slug: Leads::CallGuestcards::CALL_CENTER_SOURCE_SLUG)
      return [] if call_center.nil?

      Lead.includes(:property)
          .where(source: call_center, state: 'open')
          .where('leads.created_at >= ?', @now - @days.days)
          .where.not(property_id: nil)
          .where.not(id: CallGuestcardPush.select(:lead_id))
          .order(:created_at).to_a
          .select { |lead| lead.property.voyager_property_code.present? }
    end

    # Returns a report Hash. A real run queues the candidates; the pusher
    # resolves them on its schedule (or via rake leads:push_call_guestcards).
    def call
      leads = candidates
      @dry_run ? simulate(leads) : queue(leads)
    end

    private

    def queue(leads)
      leads.each do |lead|
        CallGuestcardPush.create!(lead: lead, property: lead.property, referral: lead.referral,
                                  phone: PhoneNumber.format_phone(lead.phone1).presence)
      end
      { dry_run: false, queued: leads.size }
    end

    def simulate(leads)
      report = {
        dry_run: true, candidates: leads.size, since: (@now - @days.days),
        decisions: Hash.new(0), by_property: Hash.new { |hash, key| hash[key] = Hash.new(0) },
        new_cards_by_age: Hash.new(0), source_fixable: 0
      }
      return report if leads.empty?

      resolved = {} # "property|phone" => [called_at, prospect id] of the latest call resolved to a card
      linked = {}   # "property|prospect id" => true for cards linked earlier in the simulation
      @database.open do |db|
        report[:backup_as_of] = db.data_as_of
        leads.group_by(&:property).each do |property, group|
          code = property.voyager_property_code
          phones = group.filter_map { |lead| phone_of(lead) }.uniq
          cards = {}
          residents = Set.new
          phones.each_slice(PHONE_BATCH) do |batch|
            cards.merge!(db.prospects_by_phone(code, batch))
            residents.merge(db.resident_phones(code, batch))
          end

          group.each do |lead|
            outcome = simulate_lead(lead, cards: cards, residents: residents, resolved: resolved, linked: linked, report: report)
            report[:decisions][outcome] += 1
            report[:by_property][property.name][outcome] += 1
          end
        end
      end
      report
    end

    # Mirrors CallGuestcardPusher#resolve, tracking resolutions in memory
    def simulate_lead(lead, cards:, residents:, resolved:, linked:, report:)
      phone = phone_of(lead)
      return CallGuestcardPush::SKIPPED_NO_PHONE if phone.nil?

      key = "#{lead.property_id}|#{phone}"
      prior = resolved[key]
      prior_prospect_id = prior[1] if prior && prior[0] >= lead.created_at - CallGuestcardPusher::REPEAT_CALL_WINDOW
      decision, card = CallGuestcardPusher.decide(called_at: lead.created_at, cards: cards.fetch(phone, []),
                                                  resident: residents.include?(phone), prior_prospect_id: prior_prospect_id)
      unless decision == :resident
        resolved[key] = [lead.created_at, card&.prospect_id || prior_prospect_id || "new card for Lead #{lead.id}"]
      end

      if %i[link_new_card link_existing_card].include?(decision)
        card_key = "#{lead.property_id}|#{card.prospect_id}"
        held = linked[card_key] || Lead.where(remoteid: card.prospect_id, property_id: lead.property_id).exists?
        linked[card_key] = true
        return CallGuestcardPush::DUPLICATE_LEAD if held
      end

      if decision == :create
        age = ((@now - lead.created_at) / 1.day).floor
        report[:new_cards_by_age][AGE_BUCKETS.find { |_label, range| range.cover?(age) }.first] += 1
      elsif decision == :link_new_card && lead.referral.present? && !card.source.to_s.strip.casecmp?(lead.referral.strip) &&
            card.status.to_s.strip.casecmp?('Prospect')
        report[:source_fixable] += 1
      end
      CallGuestcardPusher::DECISION_STATUSES.fetch(decision)
    end

    def phone_of(lead)
      phone = PhoneNumber.format_phone(lead.phone1)
      phone.length == 10 ? phone : nil
    end
  end
end
