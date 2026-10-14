module Residents
  module Adapters
    # Imports residents from the Yardi backup database (Yardi::Backup::Database):
    # every current, future, notice, eviction and past tenant plus their
    # household members (roommates, spouses, guarantors, occupants). This is
    # what Leads::ResidentValidator and Lead.open_possible_residents match
    # incoming leads against, so it is the creation-time half of the resident
    # check; Leads::YardiResidentGate is the push-time half.
    #
    # Same interface as Residents::Adapters::YardiVoyager (the SOAP import,
    # kept for environments without the backup credentials):
    #
    #   Residents::Adapters::YardiBackup.sync(['1002edge'], true, dry_run: true)
    #
    # Primary tenants keep Yardi's tenant code as residentid (t0225446, the
    # same code the SOAP import stored); members get "<tenant code>-<prospect code>".
    # Statuses map to Bluesky's current/former (yardi_status keeps the word).
    # Residents of the property that Yardi no longer lists are set to former,
    # unless the listing looks incomplete (MIN_CURRENT_RATIO): an empty or
    # partial read must never flip a whole property to former.
    class YardiBackup
      MIN_CURRENT_RATIO = 0.5
      PHONE_LIMIT = 2

      attr_reader :property, :property_code

      def self.sync(properties = nil, debug = false, dry_run: false, database: Yardi::Backup::Database)
        active_properties = resolve_properties(properties)
        database.open do |db|
          active_properties.each do |property|
            service = new(property, db: db, dry_run: dry_run)
            next if service.property_code.blank?

            puts "\n*** #{dry_run ? 'Checking' : 'Fetching and processing'} Residents for #{property.name} (#{service.property_code})" if debug
            response = service.processResidents
            puts format_response(response) if debug
          end
        end
        true
      rescue Yardi::Backup::Database::Unavailable => e
        msg = "Residents::Adapters::YardiBackup: Yardi backup unavailable (#{e.message}); residents import skipped until the next run"
        puts msg if debug
        Rails.logger.warn(msg)
        false
      end

      def self.resolve_properties(properties)
        active_properties = Property.active
        if properties&.first.is_a?(String)
          active_properties = properties.map { |propertyid| Leads::Adapters::YardiVoyager.property(propertyid) }.compact
        elsif properties&.first.is_a?(Property)
          active_properties = properties
        end
        active_properties.select(&:active?)
      end

      def self.format_response(response)
        stats = response[:stats]
        <<~EOS
          == #{response[:status].to_s.upcase} == #{response[:errors].join("\n")}
            - Processed #{response[:collection].size} Resident records (#{stats[:members]} household members)
            - #{stats[:created]} created, #{stats[:updated]} updated, #{stats[:noop]} unchanged, #{stats[:former]} marked former, #{stats[:errors]} failed
            - by status: #{stats[:by_status].map { |status, n| "#{status}=#{n}" }.join(' ')}
            - by relationship: #{stats[:by_relationship].map { |rel, n| "#{rel}=#{n}" }.join(' ')}
        EOS
      end

      def initialize(property, db:, dry_run: false)
        @property = property
        @property_code = property.voyager_property_code
        @db = db
        @dry_run = dry_run
      end

      # Returns { status: :ok | :warn | :error, collection: [Resident], stats: {...}, errors: [String] }
      def processResidents
        stats = { created: 0, updated: 0, noop: 0, errors: 0, former: 0, members: 0,
                  by_status: Hash.new(0), by_relationship: Hash.new(0) }
        errors = []
        status = nil
        residents = []

        remote = @db.residents(@property_code)
        existing_current = Resident.where(property_id: @property.id, status: 'current').count
        current_remote = remote.count { |person| person.status != 'past' }
        if remote.empty? || current_remote < existing_current * MIN_CURRENT_RATIO
          msg = "#{@property.name}: Yardi backup listed #{current_remote} current residents against #{existing_current} " \
                'in Bluesky; the listing looks incomplete, so nothing was changed'
          return { status: :warn, collection: [], stats: stats, errors: [msg] }
        end

        seen = []
        Resident.transaction do
          remote.each do |person|
            resident = resident_from_backup(person)
            seen << resident.residentid
            stats[:members] += 1 unless person.primary?
            stats[:by_status][person.status] += 1
            stats[:by_relationship][person.relationship] += 1
            residents << resident

            new_record = resident.new_record?
            changed = new_record || resident.changed? || resident.detail.changed?
            if @dry_run
              stats[new_record ? :created : (changed ? :updated : :noop)] += 1
            elsif resident.save
              stats[new_record ? :created : (changed ? :updated : :noop)] += 1
            else
              status ||= :warn
              errors << "#{@property.name} => #{new_record ? 'New ' : ''}Resident '#{person.name}' (#{resident.residentid}) " \
                        "could not be saved: #{resident.errors.full_messages.join(';')}"
              stats[:errors] += 1
            end
          end

          stats[:former] = mark_former(seen)
        end

        { status: status || :ok, collection: residents, stats: stats, errors: errors }
      rescue Yardi::Backup::Database::Unavailable
        raise
      rescue StandardError => e
        { status: :error, collection: residents, stats: stats, errors: errors + [e.message] }
      end

      private

      def resident_from_backup(person)
        residentid = person.primary? ? person.tenant_code : "#{person.tenant_code}-#{person.prospect_code || person.prospect_hmy}"
        resident = Resident.find_by(residentid: residentid) || Resident.new(residentid: residentid, property_id: @property.id)
        resident.detail ||= ResidentDetail.new
        unit = unit_for(person.unit)
        resident.unit_id = unit.id if unit
        resident.status = person.status == 'past' ? 'former' : 'current'
        resident.yardi_status = person.status
        resident.relationship = person.relationship
        resident.first_name = person.first_name
        resident.last_name = person.last_name
        phones = (person.phones - property_phones).first(PHONE_LIMIT)
        resident.detail.phone1 = phones[0]
        resident.detail.phone2 = phones[1]
        resident.detail.email = person.email
        resident
      end

      # Current residents of the property Yardi no longer lists. Manually
      # entered residents (Resident::MANUAL_RESIDENTID) are left alone.
      def mark_former(seen)
        stale = Resident.where(property_id: @property.id, status: 'current').where.not(residentid: seen)
                        .where('residentid !~ ?', Resident::MANUAL_RESIDENTID_SQL)
        return stale.count if @dry_run

        stale.find_each.count { |resident| resident.update(status: 'former') }
      end

      def unit_for(code)
        return nil if code.blank?

        @units ||= @property.housing_units.each_with_object({}) do |unit, index|
          index[unit_key(unit.unit)] = unit
        end
        @units[unit_key(code)]
      end

      def unit_key(code)
        code.to_s.strip.upcase.sub(/\A0+(?=\d)/, '')
      end

      def property_phones
        @property_phones ||= [@property.phone, @property.leasing_phone, @property.maintenance_phone]
                             .map { |phone| PhoneNumber.format_phone(phone) }.select(&:present?)
      end
    end
  end
end
