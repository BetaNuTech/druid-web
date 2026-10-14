module Yardi
  module Backup
    # Read-only access to the Yardi Voyager SQL Server backup (the same
    # database Cobalt2 reports from). Used to check whether a caller already
    # has a guest card: Voyager's SOAP search misses most existing cards.
    #
    # The backup is a log-shipped copy. Yardi takes a log backup every 30
    # minutes and it is restored ~29 minutes later, so the data trails real
    # time by 30-60 minutes; #data_as_of reports exactly how current it is.
    #
    # Settings (same names as Cobalt2): YARDI_BACKUP_DB_HOST, _PORT (default
    # 1433), _NAME, _USER, _PASS, plus the SOCKS proxy (Yardi::Backup::SocksTunnel).
    class Database
      class Error < StandardError; end
      class ConfigurationError < Error; end
      # The backup is briefly unreadable while a log backup is restored (every
      # 30 minutes, at about :29 and :59 UTC) or when the connection drops.
      # Callers wait for the next run rather than treating this as a failure.
      class Unavailable < Error; end

      REQUIRED_ENV = %w[YARDI_BACKUP_DB_HOST YARDI_BACKUP_DB_NAME YARDI_BACKUP_DB_USER YARDI_BACKUP_DB_PASS].freeze
      DEFAULT_PORT = 1433
      # Backup history timestamps are wall-clock time on Yardi's server
      SOURCE_TIME_ZONE_ENV = 'YARDI_BACKUP_SOURCE_TIME_ZONE'.freeze
      DEFAULT_SOURCE_TIME_ZONE = 'America/New_York'.freeze
      CLOCK_SKEW = 2.minutes
      # How long .open keeps trying while a restore is in progress
      RESTORE_RETRIES = 3
      RESTORE_WAIT = 20 # seconds
      RESTORING_ERROR = Regexp.union(
        ['middle of a restore', 'in transition', 'not accessible', 'DBPROCESS is dead', 'Read from the server failed',
         'connection is closed', 'Adaptive Server connection', 'Unable to connect', 'timed out']
          .map { |text| /#{Regexp.escape(text)}/i }
      )
      PROSPECT_PHONE_COLUMNS = %w[sTelCell sTelHome sTelOffice sTelAlt].freeze
      TENANT_PHONE_COLUMNS = (0..9).map { |i| "SPHONENUM#{i}" }.freeze
      # TENANT.ISTATUS: current, future, eviction, notice. Past tenants calling
      # again are treated as prospects.
      RESIDENT_STATUSES = [0, 2, 3, 4].freeze
      ISTATUS_WORDS = { 0 => 'current', 1 => 'past', 2 => 'future', 3 => 'eviction', 4 => 'notice' }.freeze
      # Everyone the residents import keeps: resident statuses plus past tenants
      IMPORT_STATUSES = ISTATUS_WORDS.keys.freeze
      # A household's people: the primary tenant (TENANT, plus its own PROSPECT
      # row at TENANT.hProspect) and the members (PROSPECT rows whose hParent is
      # that PROSPECT): roommates, spouses, guarantors, occupants, children.
      # Phones in the order they are trusted: the person's own card first.
      HOUSEHOLD_PHONE_COLUMNS = (%w[tel_cell tel_home tel_alt tel_office] + (0..9).map { |i| "tel_#{i}" }).freeze
      HOUSEHOLD_EMAIL_COLUMNS = %w[email_1 email_2].freeze
      PRIMARY_RELATIONSHIP = 'Tenant'.freeze
      MEMBER_DEFAULT_RELATIONSHIP = 'Occupant'.freeze

      Prospect = Struct.new(:prospect_id, :created_at, :source, :agent, :created_by, :status,
                            :first_name, :last_name, :relationship, keyword_init: true) do
        def primary?
          relationship.blank?
        end
      end

      # A resident household person: a primary tenant or one of its members.
      # status is an ISTATUS_WORDS value; phones are 10-digit, own card first.
      Resident = Struct.new(:tenant_code, :prospect_code, :prospect_hmy, :first_name, :last_name, :unit,
                            :status, :relationship, :phones, :email, :move_in, :move_out, keyword_init: true) do
        def primary?
          relationship == PRIMARY_RELATIONSHIP
        end

        def guarantor?
          relationship.to_s.casecmp?('Guarantor')
        end

        def name
          [first_name, last_name].map(&:presence).compact.join(' ')
        end

        # e.g. "Zoe Ellis, unit 0406, notice (Tenant t0225446)" or
        # "Hunter Brown, unit 0406, current (Roommate of t0225272, p0523236)"
        def description
          who = primary? ? "#{relationship} #{tenant_code}" : "#{relationship} of #{tenant_code}, #{prospect_code}"
          "#{name.presence || 'unnamed'}, unit #{unit.presence || '?'}, #{status} (#{who})"
        end
      end

      # A guest card event (PROSPECT_HISTORY). event_id (hMy) is the EventID
      # Voyager's guest card interface uses.
      Event = Struct.new(:event_id, :event_type, :date, :time, :agent, :notes, keyword_init: true) do
        # The event's wall-clock date and time, as Voyager shows it
        def occurred_at
          clock = time.present? ? Time.strptime(time, '%I:%M %p') : date
          Time.utc(date.year, date.month, date.day, clock.hour, clock.min)
        end
      end

      def self.configured?(env = ENV)
        REQUIRED_ENV.all? { |name| env[name].present? }
      end

      # Yields a connected, readable Database and always closes it (and its
      # tunnel). Connecting and the readiness probe (#data_as_of) are retried
      # across a log restore; after that the last error is raised, so a
      # restore that takes longer surfaces as Unavailable.
      def self.open(env: ENV, retries: RESTORE_RETRIES, wait: RESTORE_WAIT)
        database = connect_with_retries(env: env, retries: retries, wait: wait)
        yield database
      ensure
        database&.close
      end

      # A connected Database the caller closes itself (Leads::YardiResidentGate
      # keeps one open across several properties).
      def self.connect_with_retries(env: ENV, retries: RESTORE_RETRIES, wait: RESTORE_WAIT)
        attempts = 0
        begin
          attempts += 1
          database = new(env: env).connect
          database.data_as_of
          database
        rescue Error => e
          database&.close
          raise if e.is_a?(ConfigurationError) || attempts > retries

          Rails.logger.info("Yardi::Backup::Database: #{e.message}; retrying in #{wait}s " \
                            "(attempt #{attempts} of #{retries + 1})")
          sleep(wait)
          retry
        end
      end

      def initialize(env: ENV)
        @env = env
      end

      def connect
        missing = REQUIRED_ENV.reject { |name| @env[name].present? }
        raise ConfigurationError, "Missing Yardi backup database setting(s): #{missing.join(', ')}" if missing.any?

        require 'tiny_tds'
        host = @env['YARDI_BACKUP_DB_HOST']
        port = Integer(@env['YARDI_BACKUP_DB_PORT'].presence || DEFAULT_PORT)
        if (proxy = SocksTunnel.from_env(@env))
          @tunnel = SocksTunnel.new(proxy: proxy, target_host: host, target_port: port).open
          host = '127.0.0.1'
          port = @tunnel.local_port
        end

        @client = TinyTds::Client.new(
          host: host, port: port,
          database: @env['YARDI_BACKUP_DB_NAME'],
          username: @env['YARDI_BACKUP_DB_USER'],
          password: @env['YARDI_BACKUP_DB_PASS'],
          appname: 'Bluesky', login_timeout: 20, timeout: 60
        )
        self
      rescue TinyTds::Error => e
        close
        raise Error, "Could not connect to the Yardi backup database: #{e.message}"
      end

      def close
        @client&.close
        @client = nil
        @tunnel&.close
        @tunnel = nil
      end

      # The point in time (UTC) the restored data reflects. Uses the latest
      # restored log backup; falls back to the newest guest card activity
      # (always a safe lower bound) when backup history is unreadable or
      # inconsistent. Raises Unavailable when the data cannot be read at all
      # (no row or NULL: seen while a log restore is in progress).
      def data_as_of
        @data_as_of ||= begin
          newest_activity = select_rows('SELECT MAX(dtCreatedUTC) AS newest FROM PROSPECT_HISTORY').first
                            &.fetch('newest', nil)
          if newest_activity.nil?
            raise Unavailable, 'Yardi backup database reported no data time (a log restore may be in progress)'
          end

          restore = latest_restore
          backup_time = restore && source_time(restore['backup_finish_date'])
          consistent = backup_time &&
                       backup_time >= newest_activity - CLOCK_SKEW &&
                       backup_time <= restore['restore_date'] + CLOCK_SKEW
          consistent ? backup_time : newest_activity
        end
      end

      # Guest cards at the property with a phone matching one of `phones`
      # (on any of the four phone fields). Returns { phone => [Prospect] }.
      def prospects_by_phone(property_code, phones)
        phones = normalize_phones(phones)
        return {} if phones.empty?

        rows = select_rows(<<~SQL)
          SELECT RTRIM(pr.sCode) AS prospect_id, pr.dtCreatedUTC AS created_at,
                 RTRIM(pr.sSource) AS source, RTRIM(pr.sAgent) AS agent, RTRIM(u.UNAME) AS created_by,
                 RTRIM(pr.sStatus) AS status, RTRIM(pr.sFirstName) AS first_name,
                 RTRIM(pr.sLastName) AS last_name, RTRIM(pr.sRelationship) AS relationship,
                 #{PROSPECT_PHONE_COLUMNS.map { |column| "pr.#{column}" }.join(', ')}
          FROM PROSPECT pr
          JOIN PROPERTY p ON p.HMY = pr.HPROPERTY
          LEFT JOIN PMUSER u ON u.HMY = pr.hUserCreatedBy
          WHERE RTRIM(p.SCODE) = '#{escape(property_code)}'
            AND (#{suffix_filter('pr', PROSPECT_PHONE_COLUMNS, phones)})
        SQL

        rows.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |row, index|
          prospect = Prospect.new(row.slice(*Prospect.members.map(&:to_s)).symbolize_keys)
          (row_phones(row, PROSPECT_PHONE_COLUMNS) & phones).each { |phone| index[phone] << prospect }
        end
      end

      # One guest card by its ProspectID (e.g. p0523280), or nil.
      def prospect(property_code, prospect_id)
        row = select_rows(<<~SQL).first
          SELECT RTRIM(pr.sCode) AS prospect_id, pr.dtCreatedUTC AS created_at,
                 RTRIM(pr.sSource) AS source, RTRIM(pr.sAgent) AS agent, RTRIM(u.UNAME) AS created_by,
                 RTRIM(pr.sStatus) AS status, RTRIM(pr.sFirstName) AS first_name,
                 RTRIM(pr.sLastName) AS last_name, RTRIM(pr.sRelationship) AS relationship
          FROM PROSPECT pr
          JOIN PROPERTY p ON p.HMY = pr.HPROPERTY
          LEFT JOIN PMUSER u ON u.HMY = pr.hUserCreatedBy
          WHERE RTRIM(p.SCODE) = '#{escape(property_code)}' AND RTRIM(pr.sCode) = '#{escape(prospect_id)}'
        SQL
        row && Prospect.new(row.symbolize_keys)
      end

      # The first-contact events on a guest card (normally exactly one).
      def first_contact_events(property_code, prospect_id)
        select_rows(<<~SQL).map { |row| Event.new(row.symbolize_keys) }
          SELECT ph.hMy AS event_id, RTRIM(ph.sType) AS event_type, ph.dtDate AS date, RTRIM(ph.sTime) AS time,
                 RTRIM(ph.sAgent) AS agent, CAST(ph.sNotes AS varchar(max)) AS notes
          FROM PROSPECT_HISTORY ph
          JOIN PROSPECT pr ON pr.HMY = ph.HPROSPECT
          JOIN PROPERTY p ON p.HMY = pr.HPROPERTY
          WHERE RTRIM(p.SCODE) = '#{escape(property_code)}' AND RTRIM(pr.sCode) = '#{escape(prospect_id)}'
            AND ph.bFirstContact <> 0
        SQL
      end

      # Yardi ProspectIDs are not unique: an August 2026 import at The Yancey
      # reused codes that Voyager later issued at other properties. True when
      # more than one guest card carries this ID.
      def prospect_id_shared?(prospect_id)
        select_rows(<<~SQL).first['n'].to_i > 1
          SELECT COUNT(*) AS n FROM PROSPECT WHERE RTRIM(sCode) = '#{escape(prospect_id)}'
        SQL
      end

      # The current (or future/notice/eviction) residents of the property
      # reachable at one of `phones` or `emails`: primary tenants and their
      # household members alike. Returns { phone_or_email => [Resident] },
      # keyed by the 10-digit phone or lower-cased email that matched.
      def residents_by_contact(property_code, phones:, emails: [])
        phones = normalize_phones(phones)
        emails = normalize_emails(emails)
        return {} if phones.empty? && emails.empty?

        filters = []
        filters << suffix_filter('h', HOUSEHOLD_PHONE_COLUMNS, phones) if phones.any?
        if emails.any?
          email_list = emails.map { |email| "'#{escape(email)}'" }.join(', ')
          filters << HOUSEHOLD_EMAIL_COLUMNS.map { |column| "LOWER(RTRIM(h.#{column})) IN (#{email_list})" }
                                            .join(' OR ')
        end
        rows = select_rows(<<~SQL)
          SELECT h.* FROM (#{household_sql(property_code, RESIDENT_STATUSES)}) h
          WHERE #{filters.join(' OR ')}
          ORDER BY h.tenant_code, h.kind DESC, h.prospect_hmy
        SQL

        rows.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |row, index|
          resident = resident_from_row(row)
          (resident.phones & phones).each { |phone| index[phone] << resident }
          index[resident.email] << resident if resident.email && emails.include?(resident.email)
        end
      end

      # Everyone the residents import keeps for the property: current, future,
      # notice, eviction and past tenants with their household members.
      def residents(property_code)
        select_rows(<<~SQL).map { |row| resident_from_row(row) }
          SELECT h.* FROM (#{household_sql(property_code, IMPORT_STATUSES)}) h
          ORDER BY h.tenant_code, h.kind DESC, h.prospect_hmy
        SQL
      end

      private

      # Primary tenants and household members at the property as one row
      # shape: kind ('tenant' or 'member'), identity, unit, ISTATUS, the
      # relationship, every phone column and two email columns. Joins on
      # hProspect/hParent carry > 0 on both sides: those columns are 0 when
      # unset, and an unguarded join multiplies every past tenant by every
      # unparented prospect.
      def household_sql(property_code, statuses)
        code = escape(property_code)
        status_list = statuses.join(', ')
        tenant_phones = TENANT_PHONE_COLUMNS.each_with_index.map { |column, i| "t.#{column} AS tel_#{i}" }.join(', ')
        no_tenant_phones = (0..9).map { |i| "NULL AS tel_#{i}" }.join(', ')
        <<~SQL
          SELECT 'tenant' AS kind, RTRIM(t.SCODE) AS tenant_code, RTRIM(pr.sCode) AS prospect_code, pr.hMy AS prospect_hmy,
                 RTRIM(t.SFIRSTNAME) AS first_name, RTRIM(t.SLASTNAME) AS last_name,
                 RTRIM(ISNULL(u.SCODE, t.SUNITCODE)) AS unit, t.ISTATUS AS istatus, '#{PRIMARY_RELATIONSHIP}' AS relationship,
                 pr.sTelCell AS tel_cell, pr.sTelHome AS tel_home, pr.sTelAlt AS tel_alt, pr.sTelOffice AS tel_office,
                 #{tenant_phones}, t.SEMAIL AS email_1, pr.sEmail AS email_2,
                 t.DTMOVEIN AS move_in, t.DTMOVEOUT AS move_out
          FROM TENANT t
          JOIN PROPERTY p ON p.HMY = t.HPROPERTY
          LEFT JOIN UNIT u ON u.HMY = t.HUNIT
          LEFT JOIN PROSPECT pr ON pr.hMy = t.hProspect AND t.hProspect > 0
          WHERE RTRIM(p.SCODE) = '#{code}' AND t.ISTATUS IN (#{status_list})
          UNION ALL
          SELECT 'member' AS kind, RTRIM(t.SCODE) AS tenant_code, RTRIM(c.sCode) AS prospect_code, c.hMy AS prospect_hmy,
                 RTRIM(c.sFirstName) AS first_name, RTRIM(c.sLastName) AS last_name,
                 RTRIM(ISNULL(u.SCODE, t.SUNITCODE)) AS unit, t.ISTATUS AS istatus,
                 CASE WHEN RTRIM(ISNULL(c.sRelationship, '')) = '' THEN '#{MEMBER_DEFAULT_RELATIONSHIP}' ELSE RTRIM(c.sRelationship) END AS relationship,
                 c.sTelCell AS tel_cell, c.sTelHome AS tel_home, c.sTelAlt AS tel_alt, c.sTelOffice AS tel_office,
                 #{no_tenant_phones}, c.sEmail AS email_1, NULL AS email_2,
                 t.DTMOVEIN AS move_in, t.DTMOVEOUT AS move_out
          FROM TENANT t
          JOIN PROPERTY p ON p.HMY = t.HPROPERTY
          LEFT JOIN UNIT u ON u.HMY = t.HUNIT
          JOIN PROSPECT c ON c.hParent = t.hProspect AND t.hProspect > 0 AND c.hParent > 0
          WHERE RTRIM(p.SCODE) = '#{code}' AND t.ISTATUS IN (#{status_list})
            AND (c.sStatus IS NULL OR RTRIM(c.sStatus) NOT LIKE 'Cancel%')
        SQL
      end

      def resident_from_row(row)
        Resident.new(
          tenant_code: row['tenant_code'], prospect_code: row['prospect_code'].presence,
          prospect_hmy: row['prospect_hmy']&.to_i,
          first_name: row['first_name'].presence, last_name: row['last_name'].presence, unit: row['unit'].presence,
          status: ISTATUS_WORDS.fetch(row['istatus'].to_i, 'unknown'), relationship: row['relationship'].presence,
          phones: row_phones(row, HOUSEHOLD_PHONE_COLUMNS),
          email: HOUSEHOLD_EMAIL_COLUMNS.filter_map { |column| normalize_emails([row[column]]).first }.first,
          move_in: row['move_in'], move_out: row['move_out']
        )
      end

      def latest_restore
        select_rows(<<~SQL).first
          SELECT TOP 1 rh.restore_date, bs.backup_finish_date
          FROM msdb.dbo.restorehistory rh
          JOIN msdb.dbo.backupset bs ON bs.backup_set_id = rh.backup_set_id
          WHERE rh.destination_database_name = DB_NAME()
          ORDER BY rh.restore_date DESC
        SQL
      rescue TinyTds::Error => e
        Rails.logger.warn("Yardi::Backup::Database: backup history unreadable (#{e.message}); using newest activity")
        nil
      end

      # Datetimes are read as UTC (they are UTC for every *UTC column and for
      # the restore server); backup history is Yardi's local wall-clock time.
      def source_time(time)
        return nil if time.nil?

        zone = ActiveSupport::TimeZone[@env[SOURCE_TIME_ZONE_ENV].presence || DEFAULT_SOURCE_TIME_ZONE]
        zone.local(time.year, time.month, time.day, time.hour, time.min, time.sec).utc
      end

      def select_rows(sql)
        raise Error, 'Yardi backup database is not connected' unless @client

        @client.execute(sql).each(as: :hash, timezone: :utc)
      rescue TinyTds::Error => e
        raise Unavailable, "Yardi backup database is unavailable: #{e.message}" if e.message.match?(RESTORING_ERROR)

        raise
      end

      def escape(value)
        @client.escape(value.to_s)
      end

      # Narrow by the last four digits in SQL (formats vary: 6155551234,
      # (615) 555-1234); exact 10-digit matching happens in Ruby.
      def suffix_filter(table, columns, phones)
        suffixes = phones.map { |phone| phone[-4..] }.uniq
        columns.product(suffixes).map { |column, suffix| "#{table}.#{column} LIKE '%#{suffix}'" }.join(' OR ')
      end

      def row_phones(row, columns)
        normalize_phones(columns.map { |column| row[column] })
      end

      # 10-digit numbers only, minus placeholders such as 0000000000
      def normalize_phones(phones)
        Array(phones).map { |phone| PhoneNumber.format_phone(phone) }.grep(/\A\d{10}\z/)
                     .reject { |phone| ignored_value?(phone) }.uniq
      end

      def normalize_emails(emails)
        Array(emails).map { |email| email.to_s.strip.downcase }.select { |email| email.include?('@') }
                     .reject { |email| ignored_value?(email) }.uniq
      end

      def ignored_value?(value)
        Lead::DUPLICATE_IGNORED_VALUES.any? { |ignored| ignored.to_s.casecmp?(value) }
      end
    end
  end
end
