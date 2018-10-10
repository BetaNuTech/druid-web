namespace :leads do

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
        # At this time UPDATES ARE NOT SUPPORTED by Druid
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
  end

  desc "Calculate and Set Lead Priorities"
  task :prioritize => :environment do
    puts " * Setting Lead Priorities"
    Lead.set_priorities
    puts "Done."
  end
end
