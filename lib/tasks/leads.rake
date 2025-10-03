namespace :leads do

  desc 'Reassign leads (USAGE: rake leads:reassign[from@example.com,to@example.com])'
  task :reassign, [:from, :to] => :environment do |t, args|
    from_user = User.find_by_email(args[:from]) rescue nil
    to_user = User.find_by_email(args[:to]) rescue nil

    raise 'Invalid origin user email address' if from_user.nil?
    raise 'Invalid destination user email address' if to_user.nil?

    puts "*** Reassigning active leads for #{from_user.name} to #{to_user.name}..."
    from_user.reassign_leads(user: to_user)
    puts "Done."
  end

  desc "Detect and associate Residents"
  task auto_lodge: :environment do
    puts "*** Automatically lodging leads matching current residents..."
    service = Residents::LeadMatcher.new
    matches = service.call
    matches.each do |match|
      puts " - #{match[:lead].name} [#{match[:lead].id}] => #{match[:resident].name} [#{match[:resident].id}]"
    end
    puts "* Done processing leads"
  end

  namespace :referrals do
    task standardize: :environment do
      puts "*** Standardizing Lead Referrals..."

      process_leads = ->(referrals, new_referral) { Lead.where(referral: referrals).update_all(referral: new_referral) }

      Lead.transaction do
        process_leads.call(['360', '360\'s', '360\'s Tours', '360 Tours'], '360\'s Tours')
        process_leads.call(['Apartmentlist', 'Apartment List', 'Apartmentlist.com', 'Apartment List Phone'], 'ApartmentList.com')
        process_leads.call(['Apartments.com Email'], 'Apartments.com')
        process_leads.call(['Craigslist'], 'CraigsList.com')
        process_leads.call(['Drive By'], 'Drive-by')
        process_leads.call(['LeadMail'], 'Lead Mail')
        process_leads.call(['Null'], 'None')
        process_leads.call(['Facebook', 'facebook', 'Facebook Email', 'Facebook Phone', 'FaceBook.com'], 'Facebook.com')
        process_leads.call(['Forrent','For Rent','Forrent.com', 'Apartments.com/ForRent'], 'ForRent.com')
        process_leads.call(['Google','Google search', 'Google Search'], 'Google.com')
        process_leads.call(['Hotpads','HotPads.com'], 'Hotpads.com')
        process_leads.call(['Knoxville Guide'], 'KnoxvilleApartmentGuide.com')
        process_leads.call(['RentPath LeadMail','Rentpath','Rent Path','RentPath','Rentpath.com','RentPath.com'], 'Rent.com')
        process_leads.call(['Resident Referral','Resident'], 'Referral')
        process_leads.call(['Zillow', 'Zillow Email'], 'Zillow.com')
        process_leads.call(['Zumper', 'Zumper Phone'], 'Zumper.com')
        process_leads.call(['Rent.com & ApartmentGuide'], 'Rent.com')
        process_leads.call(['abodo', 'Abodo', 'Abodo Email', 'Abodo Phone','Rentable_Abodo', 'Abodo.com', 'Rentable/Abodo', 'Rentable'], 'Rentable.com')
      end
    end
  end

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
      end_date = ( Date.current + 1.day ).strftime("%Y-%m-%d")
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

  desc "Disqualify Null"
  task :disqualify_null => :environment do
    Lead.open.where(referral: 'Null').each do |lead|
      lead.classification = :parse_failure
      lead.disqualify
      lead.save
      print '.'
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

    filename = File.join("tmp", "leads-#{DateTime.current.strftime("%Y%m%d")}.csv")

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

    Lead.open.where("created_at < ?", (Date.current - 7.days)).each{|l| l.destroy}
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
        adapter = Leads::Adapters::YardiVoyager.new(property[:property])

        msg = " * Processing Leads for #{property[:name]} [YARDI ID: #{property[:code]}]"
        puts msg
        Rails.logger.warn msg
        leads = adapter.processLeads(start_date: start_date, end_date: DateTime.current)
        msg = " * Processing Residents for #{property[:name]} [YARDI ID: #{property[:code]}]"
        puts msg
        Rails.logger.warn msg
        residents = adapter.processResidents(start_date: start_date, end_date: DateTime.current)

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
    task :send_guestcards, [:minutes_ago] => :environment do |t, args|

      if (minutes_ago = args[:minutes_ago]).present?
        start_date = minutes_ago.to_i.minutes.ago
      else
        start_date = 1.day.ago
      end

      properties = property_codes = Leads::Adapters::YardiVoyager.property_codes

      if ( env_properties = ENV.fetch('PROPERTY', nil) ).present?
        env_properties = env_properties.split(',')
        properties = properties.select{|p| env_properties.include?(p[:code])}
        if properties.empty?
          properties = property_codes
        end
      end

      properties.each do |property|
        # property => { name: 'Property Name', code: 'voyagerpropertyid', property: #<Property> }
        msg = " * Sending Leads to Yardi Voyager as GuestCards for #{property[:name]} [YARDI ID: #{property[:code]}]"
        puts msg
        Rails.logger.warn msg
        adapter = Leads::Adapters::YardiVoyager.new(property[:property])

        reporter = -> (leads, desc) {
          leads_count = leads.size
          leads_succeeded = leads.select{|l| l.remoteid.present? }.size
          leads_failures = leads.select{|l| !l.errors.empty? || !l.remoteid.present? }.map do |record|
            "FAIL: #{property[:name]}: #{record.name} [Lead ID: #{record.id}]: #{record.errors.to_a.join(', ')}"
          end
          leads_msg=<<~EOS
            - Processed #{leads_count} Records #{desc}
            - #{leads_succeeded} Records saved
            - #{leads_failures.size} Failed
          EOS
          leads_msg += leads_failures.join("\n")
          puts leads_msg
          Rails.logger.warn leads_msg
        }

        # Send only assigned leads without a remoteid (new to Yardi Voyager) added recently
        leads = adapter.createGuestCards(start_date: start_date)
        reporter.call(leads, 'for creation')

        # Update Guestcards for active leads modified recently
        leads = adapter.updateGuestCards(start_date: start_date)
        reporter.call(leads, 'for update')

        # Cancel Guestcards for leads disqualified recently
        leads = adapter.cancelGuestCards(start_date: start_date)
        reporter.call(leads, 'to cancel')
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
      prefix = DateTime.current.to_i
      property_ids.each do |property_id|
        start_time = DateTime.current
        puts "  - Fetching #{property_id}"
        if days.present?
          guestcards = adapter.getGuestCards(property_id,
                                               start_date: days.days.ago,
                                               end_date: DateTime.current,
                                               filter: true)
        else
          guestcards = adapter.getGuestCards(property_id, filter: true)
        end
        filename = File.join(Rails.root, "tmp", "#{prefix}_#{property_id}_guestcards.csv")
        elapsed = DateTime.current.to_i - start_time.to_i
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

  namespace :incoming do
    desc "Reparse Null leads"
    task :reparse => :environment do

      start_date = 1.month.ago.beginning_of_day
      null_leads = Lead.where(created_at: start_date.., classification: 'parse_failure')
      puts "* Re-Processing #{null_leads.count} 'Null' Leads since #{start_date.to_s(:long)}"
      processed = 0
      failed = 0
      new_leads = null_leads.map do |null_lead|
        new_lead = Lead.reparse(null_lead)
        if new_lead.referral != 'Null' && new_lead.save
          puts "  - %s => %s : %s for %s from %s (%s)" % [
            null_lead.id,
            new_lead.id,
            new_lead.name,
            new_lead.property.name,
            new_lead.referral,
            null_lead.created_at
          ]
          processed += 1
        else
          puts "  - %s : %s" % [null_lead.id, null_lead.errors.to_a.to_s]
          failed += 1
        end

        new_lead
      end
      puts "DONE. #{processed} records saved out of #{new_leads.size}"

      new_leads.select{|lead| lead.valid?}.each do |new_lead|
        if new_lead.valid?
          puts " - Added: %s://%s/leads/%s" % [
            ENV['APPLICATION_PROTOCOL'],
            ENV['APPLICATION_HOST'],
            new_lead.id
          ]
        end
      end
    end
  end

  namespace :disqualified do
    desc "Reject Tasks assigned to Disqualified Leads"
    task :reject_tasks => :environment do
      skope = ScheduledAction.
        joins("INNER JOIN leads ON leads.id = scheduled_actions.target_id AND scheduled_actions.target_type = 'Lead'").
        incomplete.
        where(leads: {state: [:disqualified, :approved]})
      count = skope.count

      puts "* Rejecting tasks for Disqualified and Approved Leads"
      puts " - #{count} tasks found"
      if count > 1
        print " - rejecting tasks..."
        ScheduledAction.
            joins("INNER JOIN leads ON leads.id = scheduled_actions.target_id AND scheduled_actions.target_type = 'Lead'").
            incomplete.
            where(leads: {state: [:disqualified, :approved]}).
          update_all(state: :rejected)
      end
      puts "DONE."
    end
  end

  namespace :duplicates do
    desc "Cleanup invalid duplicate references"
    task :cleanup => :environment do
      puts "* Cleaning up Lead duplicate references..."
      start_count = DuplicateLead.count

      DuplicateLead.cleanup_invalid

      delta = start_count - DuplicateLead.count
      puts "  - #{delta} records removed"
      puts "DONE!"
    end

    desc "Disqualify if a Resident"
    task :disqualify_residents => :environment do
      puts '** Disqualifying as resident any open leads that match a current Resident record'
      Lead.disqualify_open_resident_leads
    end
  end

  namespace :waitlist do
    desc "Re-open waitlist leads whose unit preference is now available"
    task :process => :environment do
      puts "*** Opening waitlist leads whose unit preference is now available"
      puts "=> #{Lead.can_leave_waitlist.count} Leads are eligible to re-open"
      puts Lead.can_leave_waitlist.pluck(:id).join(', ')
      Lead.process_waitlist
      puts "DONE!"
    end
  end

  namespace :referrals do
    desc 'Standardize Lead referral references'
    task cleanup: :environment do
      service = Leads::Cleanup.new
      service.debug = true
      service.call
    end
  end

  desc 'Transition Leads Correlated to Residents'
  task resident_auto_transition: :environment do
    Leads::ResidentProcessor.new.call
  end

  desc "Kick the can"
  task :kick_the_can => :environment do

    properties = Leads::Adapters::YardiVoyager.property_codes
    if ( env_property = ENV.fetch('PROPERTY', nil) ).present?
      property = properties.select{|p| p[:code] == env_property}
      if property.present?
        properties = property
      end
    end

    end_date = 2.months.ago.beginning_of_month
    if (env_end_date = ENV.fetch('END_DATE', nil)).present?
      begin
        end_date = Time.parse(env_end_date)
      rescue
        # NOOP: default
      end
    end

    start_date = 5.years.ago
    follow_up_base = DateTime.current.beginning_of_day + 2.months

    unless (ENV.fetch('CONFIRM', 'true') == 'false')
      puts "*** Processing old Open Leads before #{end_date} for #{properties.count} properties (Press ENTER to continue)"
      _ = $stdin.gets
    end

    #Property.active.each do |property|
    properties.each do |record|
      property = record[:property]
      next unless property.active?

      old_leads = property.leads.open.where(created_at: start_date..end_date).order(created_at: :asc)
      puts "*** Processing #{old_leads.count} old Open leads for #{property.name}"
      next if old_leads.count < 50
      if old_leads.count > 100
        batch_size = [(old_leads.count / 90).to_i, 30].max
        old_leads.find_in_batches(batch_size: batch_size).with_index do |group, index|
          follow_up_date = follow_up_base + index.days
          puts " - Postponing #{group.count} Leads for #{property.name} until #{follow_up_date}"
          group.each do |lead|
            lead.notes = (lead.notes || '') + 'This old lead was automatically postponed for later follow-up'
            lead.follow_up_at = follow_up_date
            lead.trigger_event(event_name: :postpone, user: User.system)
          end
        end
      else
        follow_up_date = follow_up_base
        puts " - Postponing #{old_leads.count} Leads for #{property.name} until #{follow_up_date}"
        old_leads.each do |lead|
          lead.notes = (lead.notes || '') + 'This old lead was automatically postponed for later follow-up'
          lead.follow_up_at = follow_up_base
          lead.trigger_event(event_name: :postpone, user: User.system)
        end
      end
    end
  end
end
