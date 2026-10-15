module Leads
  # Keeps current Yardi residents out of guest card pushes. Every path that
  # creates a guest card (the legacy sync, the self-booked tour push, the
  # call lead push) screens its leads here first, against the Yardi backup
  # database: primary tenants and their household members (roommates,
  # spouses, occupants, guarantors) with status current, future, notice or
  # eviction, matched on phone or email.
  #
  # One gate serves a whole rake run: the backup connection is opened on the
  # first screen that has leads, kept for later properties, and closed by
  # #close. A failed open is remembered, so a restore window costs one wait,
  # not one per property. Yardi::Backup::Database::Unavailable (the backup is
  # restoring) propagates to the caller, which holds its creates until the
  # next run. See doc/yardi_resident_check.md.
  class YardiResidentGate
    CLOSABLE_STATES = %w[open prospect].freeze
    NOTE_PREFIX = 'Yardi resident check'.freeze

    attr_reader :dry_run

    # The one Resident a lead should be treated as, or nil. Guarantors only
    # match when the last name matches too: a parent guaranteeing a child's
    # lease is a legitimate prospect for a unit of their own.
    def self.matching_resident(lead, residents)
      Array(residents).find do |resident|
        !resident.guarantor? || same_last_name?(lead, resident)
      end
    end

    def self.same_last_name?(lead, resident)
      lead.last_name.present? && resident.last_name.present? && lead.last_name.strip.casecmp?(resident.last_name.strip)
    end

    def self.describe(resident)
      "matches Yardi resident #{resident.description}"
    end

    def initialize(database: Yardi::Backup::Database, dry_run: false)
      @database = database
      @dry_run = dry_run
      @db = nil
      @failure = nil
      @warned_unconfigured = false
    end

    # Splits `leads` (all at `property`) into
    #   clear:     push as usual
    #   residents: [[lead, Resident]] open/prospect leads to close out
    #   review:    [[lead, Resident]] matches in states that cannot be
    #              invalidated (showing, application, future...): hold
    # Raises Yardi::Backup::Database::Error (including Unavailable) when the
    # backup cannot be read; nothing is decided then.
    def screen(property, leads)
      result = { clear: [], residents: [], review: [] }
      leads = leads.to_a
      return result if leads.empty?

      code = property.voyager_property_code
      return result.merge(clear: leads) if code.blank? || !configured?

      contacts = leads.map { |lead| [lead, contact_keys(lead, property)] }
      phones = contacts.flat_map { |_lead, keys| keys[:phones] }.uniq
      emails = contacts.flat_map { |_lead, keys| keys[:emails] }.uniq
      index = phones.empty? && emails.empty? ? {} : db.residents_by_contact(code, phones: phones, emails: emails)

      contacts.each do |lead, keys|
        candidates = (keys[:phones] + keys[:emails]).flat_map { |key| index.fetch(key, []) }.uniq
        resident = self.class.matching_resident(lead, candidates)
        if resident.nil?
          result[:clear] << lead
        elsif CLOSABLE_STATES.include?(lead.state)
          result[:residents] << [lead, resident]
        else
          result[:review] << [lead, resident]
        end
      end
      result
    end

    # Invalidate an open/prospect lead as a resident. Returns true on success.
    def close_out(lead, resident, note_prefix: NOTE_PREFIX)
      return true if dry_run

      lead.classification = :resident
      lead.transition_memo = "#{note_prefix}: #{self.class.describe(resident)}"
      if lead.trigger_event(event_name: 'invalidate', user: User.system)
        log_block(lead, resident, 'closed before the Yardi push')
        return true
      end

      Rails.logger.error("Leads::YardiResidentGate: could not invalidate Lead[#{lead.id}]: " \
                         "#{lead.errors.full_messages.to_sentence.presence || lead.state}")
      false
    end

    # Leave a lead an agent may be working alone, but say why it was not
    # sent to Yardi (once). It is screened again on the next run.
    def hold(lead, resident, note_prefix: NOTE_PREFIX)
      return if dry_run

      content = "#{note_prefix}: not sent to Yardi, #{self.class.describe(resident)}"
      return if Note.where(notable: lead, content: content).exists?

      Note.create!(notable: lead, classification: 'system', content: content)
      log_block(lead, resident, "held before the Yardi push (#{lead.state})")
    end

    def log_block(lead, resident, stage)
      Leads::ResidentBlockLog.record(property: lead.property, stage: stage, resident: resident, lead: lead,
                                     contact: [lead.phone1, lead.phone2, lead.email].find(&:present?),
                                     source: lead.source, referral: lead.referral)
    end

    # Stands in for Yardi::Backup::Database (responds to .open) for services
    # that take a `database:`, so one rake run shares this gate's connection
    class SharedDatabase
      def initialize(gate)
        @gate = gate
      end

      def open(**)
        yield @gate.connection
      end

      def configured?
        @gate.configured?
      end
    end

    def shared_database
      SharedDatabase.new(self)
    end

    # The run's backup connection, opened on first use. A failure to open is
    # remembered for the rest of the run.
    def connection
      raise @failure if @failure

      @db ||= @database.connect_with_retries
    rescue Yardi::Backup::Database::Error => e
      @failure = e
      raise
    end

    def configured?
      @database.respond_to?(:configured?) ? @database.configured? : true
    end

    def close
      @db&.close
      @db = nil
    end

    private

    def db
      connection
    end

    def contact_keys(lead, property)
      ignored = Lead::DUPLICATE_IGNORED_VALUES
      property_phones = [property.phone, property.leasing_phone, property.maintenance_phone]
                        .map { |phone| PhoneNumber.format_phone(phone) }.select(&:present?)
      phones = [lead.phone1, lead.phone2].map { |phone| PhoneNumber.format_phone(phone) }.grep(/\A\d{10}\z/)
                                         .reject { |phone| ignored.include?(phone) || property_phones.include?(phone) }.uniq
      email = lead.email.to_s.strip.downcase
      emails = email.include?('@') && ignored.none? { |value| value.casecmp?(email) } ? [email] : []
      { phones: phones, emails: emails }
    end
  end
end
