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

  namespace :yardi do

    desc "Import GuestCards"
    task :import_guestcards => :environment do

      properties = [
        {name: 'Maplebrook', code: 'maplebr'},
        {name: 'Marble Alley', code: 'marble'},
      ]

      properties.each do |property|
        msg = " * Importing Yardi Voyager GuestCards for #{property[:name]} [YARDI ID: #{property[:code]}] as Leads"
        puts msg
        Rails.logger.warn msg
        adapter = Leads::Adapters::YardiVoyager.new({ property_code: property[:code] })
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

      lead_source = LeadSource.where(slug: 'YardiVoyager').first
      properties = [
        { name: 'Maplebrook',
          code: 'maplebr',
          property: PropertyListing.where(code: 'maplebr', source_id: lead_source.id).first.property },

        { name: 'Marble Alley',
          code: 'marble',
          property: PropertyListing.where(code: 'marble', source_id: lead_source.id).first.property }
      ]

      properties.each do |property|
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
