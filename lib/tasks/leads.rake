namespace :leads do

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


      Leads::Adapters::YardiVoyager.property_codes.each do |property|
        # property => { name: 'Property Name', code: 'voyagerpropertyid', property: #<Property> }

        msg = " * Importing Yardi Voyager GuestCards for #{property[:name]} [YARDI ID: #{property[:code]}] as Leads"
        puts msg
        Rails.logger.warn msg
        adapter = Leads::Adapters::YardiVoyager.new({
          property_code: property[:code],
          start_date: start_date,
          end_date: DateTime.now })
        leads = adapter.processLeads

        count = leads.size
        succeeded = leads.select{|l| l.id.present? }.size
        failures = leads.select{|l| !l.errors.empty?}.map do |record|
          "FAIL: #{record.name} [Yardi ID: #{record.remoteid}]: #{record.errors.to_a.join(', ')}"
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

    desc "Send GuestCards"
    task :send_guestcards => :environment do

      Leads::Adapters::YardiVoyager.property_codes.each do |property|
        # property => { name: 'Property Name', code: 'voyagerpropertyid', property: #<Property> }
        msg = " * Sending Leads to Yardi Voyager as GuestCards for #{property[:name]} [YARDI ID: #{property[:code]}]"
        puts msg
        Rails.logger.warn msg
        adapter = Leads::Adapters::YardiVoyager.new({ property_code: property[:code] })

        # Send only assigned leads without a remoteid (new to Yardi Voyager)
        # At this time UPDATES ARE NOT SUPPORTED by BlueSky
        leads_for_transfer = property[:property].leads.select{|l| l.remoteid.nil? && !l.user_id.nil? }
        leads = adapter.sendLeads(leads_for_transfer)

        count = leads.size
        succeeded = leads.select{|l| l.remoteid.present? }.size
        failures = leads.select{|l| !l.errors.empty? || !l.remoteid.present? }.map do |record|
          "FAIL: #{record.name} [Lead ID: #{record.id}]: #{record.errors.to_a.join(', ')}"
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
end
