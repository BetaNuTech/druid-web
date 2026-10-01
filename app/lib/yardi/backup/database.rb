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

      REQUIRED_ENV = %w[YARDI_BACKUP_DB_HOST YARDI_BACKUP_DB_NAME YARDI_BACKUP_DB_USER YARDI_BACKUP_DB_PASS].freeze
      DEFAULT_PORT = 1433
      # Backup history timestamps are wall-clock time on Yardi's server
      SOURCE_TIME_ZONE_ENV = 'YARDI_BACKUP_SOURCE_TIME_ZONE'.freeze
      DEFAULT_SOURCE_TIME_ZONE = 'America/New_York'.freeze
      CLOCK_SKEW = 2.minutes
      PROSPECT_PHONE_COLUMNS = %w[sTelCell sTelHome sTelOffice sTelAlt].freeze
      TENANT_PHONE_COLUMNS = (0..9).map { |i| "SPHONENUM#{i}" }.freeze
      # TENANT.ISTATUS: current, future, eviction, notice. Past tenants calling
      # again are treated as prospects.
      RESIDENT_STATUSES = [0, 2, 3, 4].freeze

      Prospect = Struct.new(:prospect_id, :created_at, :source, :agent, :created_by, :status,
                            :first_name, :last_name, :relationship, keyword_init: true) do
        def primary?
          relationship.blank?
        end
      end

      def self.configured?(env = ENV)
        REQUIRED_ENV.all? { |name| env[name].present? }
      end

      # Yields a connected Database and always closes it (and its tunnel).
      def self.open(env: ENV)
        database = new(env: env)
        database.connect
        yield database
      ensure
        database&.close
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
      # inconsistent.
      def data_as_of
        newest_activity = select_rows('SELECT MAX(dtCreatedUTC) AS newest FROM PROSPECT_HISTORY').first&.fetch('newest')
        restore = latest_restore
        backup_time = restore && source_time(restore['backup_finish_date'])
        consistent = backup_time && newest_activity &&
                     backup_time >= newest_activity - CLOCK_SKEW &&
                     backup_time <= restore['restore_date'] + CLOCK_SKEW
        consistent ? backup_time : newest_activity
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

      # The subset of `phones` belonging to current (or future/notice)
      # residents of the property.
      def resident_phones(property_code, phones)
        phones = normalize_phones(phones)
        return Set.new if phones.empty?

        rows = select_rows(<<~SQL)
          SELECT #{TENANT_PHONE_COLUMNS.map { |column| "t.#{column}" }.join(', ')}
          FROM TENANT t
          JOIN PROPERTY p ON p.HMY = t.HPROPERTY
          WHERE RTRIM(p.SCODE) = '#{escape(property_code)}'
            AND t.ISTATUS IN (#{RESIDENT_STATUSES.join(', ')})
            AND (#{suffix_filter('t', TENANT_PHONE_COLUMNS, phones)})
        SQL
        rows.flat_map { |row| row_phones(row, TENANT_PHONE_COLUMNS) }.to_set & phones
      end

      private

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
        columns.map { |column| PhoneNumber.format_phone(row[column]) }.select { |phone| phone.length == 10 }.uniq
      end

      def normalize_phones(phones)
        Array(phones).map { |phone| PhoneNumber.format_phone(phone) }.grep(/\A\d{10}\z/).uniq
      end
    end
  end
end
