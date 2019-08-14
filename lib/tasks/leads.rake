namespace :leads do

  namespace :stats do
    desc "Referral Stats (USAGE: rake leads:stats:referrals[DAYS] PROPERTY=propertycode1,propertycode2)"
    task :referrals, [:days] => :environment do |t, args|
      properties = Leads::Adapters::YardiVoyager.property_codes

      if ( env_property = ENV.fetch('PROPERTY', nil) ).present?
        property_codes = env_property.split(',').map(&:downcase)
        property = properties.select{|p| property_codes.include?(p[:code])}
        if property.present?
          properties = property
        end
      end

      start_date = nil
      if (days_ago = args[:days]).present?
        start_date = days_ago.to_i.days.ago
      else
        start_date = 7.days.ago
      end
      start_date = start_date.strftime("%Y-%m-%d")
      end_date = ( Date.today + 1.day ).strftime("%Y-%m-%d")
      data = ActiveRecord::Base.connection.execute("
        SELECT properties.name, properties.id, leads.referral, date(leads.created_at) as lead_day, count(leads.id) as lead_count
        FROM properties
        INNER JOIN leads on leads.property_id = properties.id
        WHERE
         properties.id IN (#{properties.map{|p| "'#{p[:property].id}'" }.join(', ')})
         AND leads.created_at BETWEEN '#{start_date}' AND '#{end_date}'
        GROUP BY
         properties.id, leads.referral, lead_day
        ORDER BY
         lead_day DESC").to_a

       last_property = nil
       last_day = nil
       puts "= Bluesky Lead Referrals: #{start_date} to #{end_date}"
       puts "+------------+--------------------------------+----------------------+-------+"
       puts "| %-10s | %-30s | %-20s | %-5s |" % [ "Day", "Property", "Referral", "Leads"]
       data.each do |record|
         if last_day != record["lead_day"]
           puts "+------------+--------------------------------+----------------------+-------+"
           last_property = nil
         end
        puts "| %-10s | %-30s | %-20s | %-5i |" % [
          last_day == record["lead_day"] ? '' : record["lead_day"],
          last_property == record["name"] ? '' : record["name"],
          record["referral"], record["lead_count"] || 0]
        last_day = record["lead_day"]
        last_property = record["name"]
       end
       puts "+------------+--------------------------------+----------------------+-------+"

    end
  end

  desc "Export"
  task :export, [:property_ids] => :environment do |t, args|

    if args[:property_ids].present?
      property_ids = ( args[:property_ids] || '' ).split(',')
      properties = Property.find(property_ids)
    else
      properties = Property.all
      property_ids = properties.map(&:id)
    end

    filename = File.join("tmp", "leads-#{DateTime.now.strftime("%Y%m%d")}.csv")

    puts "* Exporting CSV for Properties: #{properties.map(&:name).join(', ') || 'All'}"
    print "** Output to #{filename}"

    File.open(filename, "wb") do |file|
      file.puts Lead.export_csv(search: 'Property', ids: property_ids)
    end

    puts " Done."
  end

  desc "Cleanup"
  task :delete_old => :environment do
    puts "! DELETE OPEN LEADS OLDER THAN 1 WEEK AND ALL AUDIT RECORDS!"
    puts "(press ENTER to continue or CTRL-C to quit)"
    _c = STDIN.gets

    Lead.auditing_enabled = false
    LeadPreference.auditing_enabled = false

    Lead.open.where("created_at < ?", (Date.today - 7.days)).each{|l| l.destroy}
    Audited::Audit.destroy_all

    Lead.auditing_enabled = true
    LeadPreference.auditing_enabled = true
  end

  desc "Process Follow-Ups"
  task :process_followups => :environment do
    pending_count = Lead.pending_revisit.count
    puts "Processing Lead followups (#{pending_count})"
    Lead.process_followups
  end

  namespace :recordings do
    desc "Cleanup old non-lead recordings"
    task :cleanup => :environment do
      Cdr.cleanup_non_lead_recordings(start_date: 2.weeks.ago, end_date: 1.week.ago)
    end
  end

  namespace :calls do
    desc "Create Leads from Recent Calls"
    task :generate_leads, [:minutes_ago] => :environment do |t,args|
      minutes_ago = ( args[:minutes_ago] || 15).to_i

      msg = " * Creating Leads from recent calls up to #{minutes_ago} minutes ago"
      puts msg; Rails.logger.warn msg
      prospective_leads = Lead.from_recent_calls(start_date: minutes_ago.minutes.ago, end_date: DateTime.now).to_a

      msg = "   - Found #{prospective_leads.size} Prospective Leads"
      puts msg; Rails.logger.warn msg

      msg = "   - Processing Leads"
      puts msg; Rails.logger.warn msg
      prospective_leads.each do |lead|
        print (lead.save ? "." : "!")
      end
      puts "\n"

      failed_records = prospective_leads.select{|l| l.errors.any?}
      success_records = prospective_leads.select{|l| !l.errors.any?}
      failed_count = failed_records.size
      success_count = success_records.count

      msg = "   - Created #{success_count} Leads with #{failed_count} failures. " + success_records.map{|r| [r.id, r.first_name].join(":")}.join(' ')
      puts msg; Rails.logger.warn msg

      puts "Done."
    end

    desc "Check CDR database health"
    task :db_check => :environment do
      status = Cdr.check_replication_status
      puts "=== CDR Replication Check [#{DateTime.now.to_s}]: #{status ? "OK" : "FAILED"}"
    end
  end

  namespace :yardi do

    desc "Import GuestCards"
    task :import_guestcards, [:minutes_ago] => :environment do |t,args|
      start_date = nil
      if (minutes_ago = args[:minutes_ago]).present?
        start_date = minutes_ago.to_i.minutes.ago
      end

      msg = " * Creating Leads from Voyager GuestCards updated #{minutes_ago || '(unlimited)'} minutes ago"
      puts msg; Rails.logger.warn msg

      properties = Leads::Adapters::YardiVoyager.property_codes

      if ( env_property = ENV.fetch('PROPERTY', nil) ).present?
        property = properties.select{|p| p[:code] == env_property}
        if property.present?
          properties = property
        end
      end

      properties.each do |property|
        # property => { name: 'Property Name', code: 'voyagerpropertyid', property: #<Property> }

        msg = " * Importing Yardi Voyager GuestCards for #{property[:name]} [YARDI ID: #{property[:code]}]"
        puts msg
        Rails.logger.warn msg
        adapter = Leads::Adapters::YardiVoyager.new({
          property_code: property[:code],
          start_date: start_date,
          end_date: DateTime.now })

        msg = " * Processing Leads for #{property[:name]} [YARDI ID: #{property[:code]}]"
        puts msg
        Rails.logger.warn msg
        leads = adapter.processLeads
        msg = " * Processing Residents for #{property[:name]} [YARDI ID: #{property[:code]}]"
        puts msg
        Rails.logger.warn msg
        residents = adapter.processResidents

        lead_count = leads.size
        lead_succeeded = leads.select{|l| l.id.present? }.size
        lead_failures = leads.select{|l| !l.errors.empty?}.map do |record|
          "FAIL: #{record.name} [Yardi ID: #{record.remoteid}]: #{record.errors.to_a.join(', ')}"
        end
        resident_count = residents.size
        resident_succeeded = residents.select{|l| l.id.present? }.size
        resident_failures = residents.select{|l| !l.errors.empty?}.map do |record|
          "FAIL: #{record.name} [Yardi ID: #{record.residentid}]: #{record.errors.to_a.join(', ')}"
        end

        msg=<<~EOS
        - Processed #{leads.size} Lead Records
        - #{lead_succeeded} Lead Records saved
          - #{lead_failures.size} Failed
          - #{lead_failures.join("\n")}
        - Processed #{residents.size} Resident Records
        - #{resident_succeeded} Resident Records saved
          - #{resident_failures.size} Failed
          - #{resident_failures.join("\n")}
        EOS
        puts msg
        Rails.logger.warn msg
      end
    end

    desc "Send GuestCards"
    task :send_guestcards => :environment do

      property_codes = Leads::Adapters::YardiVoyager.property_codes

      if ( env_properties = ENV.fetch('PROPERTY', nil) ).present?
        env_properties = env_properties.split(',')
        properties = property_codes.select{|p| env_properties.include?(p[:code])}
        if properties.empty?
          properties = property_codes
        end
      end

      properties.each do |property|
        # property => { name: 'Property Name', code: 'voyagerpropertyid', property: #<Property> }
        msg = " * Sending Leads to Yardi Voyager as GuestCards for #{property[:name]} [YARDI ID: #{property[:code]}]"
        puts msg
        Rails.logger.warn msg
        adapter = Leads::Adapters::YardiVoyager.new({ property_code: property[:code] })

        # Send only assigned leads without a remoteid (new to Yardi Voyager)
        # At this time UPDATES ARE NOT SUPPORTED by BlueSky
        leads = adapter.sendLeads(property[:property].leads_for_sync)

        count = leads.size
        succeeded = leads.select{|l| l.remoteid.present? }.size
        failures = leads.select{|l| !l.errors.empty? || !l.remoteid.present? }.map do |record|
          "FAIL: #{property[:name]}: #{record.name} [Lead ID: #{record.id}]: #{record.errors.to_a.join(', ')}"
        end

        msg=<<~EOS
        - Processed #{leads.size} Records
        - #{succeeded} Records saved
        - #{failures.size} Failed
          EOS
        msg += failures.join("\n")
        puts msg
        Rails.logger.warn msg
      end
    end

    desc 'Voyager GuestCard CSV (rake leads:yardi:guestcard_csv["yardi_id1,yardi_id2, ...",days] ; default: all properties, 90 days)'
    task :guestcard_csv, [ :property_ids, :days ] => :environment do |t, args|

      property_ids = ( args[:property_ids] || "" ).split(',').map(&:strip)
      unless property_ids.present?
        source = LeadSource.where(slug: 'YardiVoyager').first
        property_ids = source.listings.map(&:code)
      end

      if (days = args[:days]).present?
        days = days.to_i
      else
        days = nil
      end

      puts "* Fetching Voyager Guestcards active within #{days} days, for Properties: #{property_ids.join(', ')}"

      adapter = Yardi::Voyager::Api::GuestCards.new
      all_guestcards = []
      prefix = DateTime.now.to_i
      property_ids.each do |property_id|
        start_time = DateTime.now
        puts "  - Fetching #{property_id}"
        if days.present?
          guestcards = adapter.getGuestCards(property_id,
                                               start_date: days.days.ago,
                                               end_date: DateTime.now,
                                               filter: true)
        else
          guestcards = adapter.getGuestCards(property_id, filter: true)
        end
        filename = File.join(Rails.root, "tmp", "#{prefix}_#{property_id}_guestcards.csv")
        elapsed = DateTime.now.to_i - start_time.to_i
        puts "  --- [#{elapsed}s]"
        puts "  --- Output #{guestcards.size} GuestCards to #{filename}"
        File.open(filename, "wb"){|f| f.puts Yardi::Voyager::Data::GuestCard.to_csv(guestcards)}
        all_guestcards += guestcards
      end

      filename = File.join(Rails.root, "tmp", "#{prefix}__guestcards.csv")
      puts " * Output all #{all_guestcards.size} Guestcards to #{filename}"
      File.open(filename, "wb"){|f| f.puts Yardi::Voyager::Data::GuestCard.to_csv(all_guestcards)}

    end

  end

  desc "Calculate and Set Lead Priorities"
  task :prioritize => :environment do
    puts " * Setting Lead Priorities"
    Lead.set_priorities
    puts "Done."
  end

  namespace :referrals do
    desc "Infer/Create Referral Records"
    task :infer => :environment do

    end
  end
end
