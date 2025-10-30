namespace :statistics do

  desc "Bootstrap Statistics and LeadSpeed"
  task :bootstrap => :environment do
    time_basis = DateTime.current.utc.beginning_of_day
    two_months_ago = time_basis.beginning_of_month - 2.months

    if ContactEvent.count < 100
      puts "*** Generating contact events for the past 2 months"
      Lead.where(created_at: two_months_ago..DateTime.current).each do |lead|
        messages = lead.messages.outgoing.where(classification: 'default').to_a
        tasks = lead.scheduled_actions.contact.completed.to_a
        (messages + tasks).sort_by(&:created_at).each do |article|
          begin
            case article
            when Message
              next if article.for_compliance?
              article.messageable.create_contact_event(
                {
                  timestamp: article.delivered_at,
                  description: 'Historical contact event for message',
                  article: article
                }
              )
            when ScheduledAction
              next unless article.target.is_a?(Lead)

              article.target.create_contact_event(
                {
                  timestamp: article.completed_at,
                  description: 'Historical contact event for task',
                  article: article
                }
              )
            end
          rescue => e
            puts "*** Error creating Contact Event for #{article.to_s}"
            puts e.to_s
            next
          end
        end
      end
    end

    ### Tenacity
    puts "*** Generating Tenacity for the past 2 months"
    Statistic.generate_tenacity(time_start: Statistic.utc_month_start - 2.months)

    puts "*** Generating Property Tenacity Statistics for the past month"
    Property.active.each{|property| Statistic.generate_property_tenacity(property: property, time_start: Statistic.utc_month_start - 1.month)}

    ### Leadspeed
    puts "*** Generating Leadspeed for the past 2 months"
    Statistic.generate_leadspeed(resolution: 60, time_start: Statistic.utc_month_start - 2.months)

    puts "*** Generating Property Leadspeed for the past 2 months"
    Property.active.each{|property| Statistic.generate_property_leadspeed(property: property, resolution: 60, time_start: Statistic.utc_month_start - 2.months)}

    puts "*** Generating Property Leadspeed for the past 2 months"
    Team.all.each{|team| Statistic.generate_team_leadspeed(team: team, resolution: 60, time_start: Statistic.utc_month_start - 2.months)}

    puts "*** Rolling up Leadspeed by day for the past 2 months"
    61.times{|i| Statistic.rollup_leadspeed(interval: :day, time_start: Statistic.utc_day_start - (i+1).days)}

    puts "*** Rolling up Leadspeed by week for the past 2 months"
    9.times{|i| Statistic.rollup_leadspeed(interval: :week, time_start: Statistic.utc_day_start - (i+1).weeks)}

    puts "*** Rolling up Leadspeed by week for the past 2 months"
    2.times{|i| Statistic.rollup_leadspeed(interval: :month, time_start: Statistic.utc_month_start - (i+1).months)}
  end

  namespace :tenacity do
    desc "generate tenacity monthly statistics"
    task :generate => :environment do
      puts "*** Generating Agent Tenacity Statistics for the past month"
      Statistic.generate_tenacity(time_start: Statistic.utc_month_start - 1.month)

      puts "*** Generating Property Tenacity Statistics for the past month"
      Property.active.each{|property| Statistic.generate_property_tenacity(property: property, time_start: Statistic.utc_month_start - 1.month)}
    end
  end

  namespace :leadspeed do
    desc "generate leadspeed hourly statistics"
    task :generate => :environment do
      puts "*** Generating LeadSpeed Statistics for the past 2 hours"
      Statistic.generate_leadspeed(resolution: 1.hour, time_start: Statistic.utc_hour_start - 2.hours)

      puts "*** Generating Property LeadSpeed Statistics for the past 2 hours"
      Property.active.each{|property| Statistic.generate_property_leadspeed(property: property, resolution: 1.hour, time_start: Statistic.utc_hour_start - 2.hours)}

      puts "*** Generating Team LeadSpeed Statistics for the past 2 hours"
      Team.all.each{|team| Statistic.generate_team_leadspeed(team: team, resolution: 60, time_start: Statistic.utc_hour_start - 2.hours)}
    end

    desc "daily backfill - catch any missed hourly statistics"
    task :backfill_daily => :environment do
      puts "*** Daily LeadSpeed Backfill: Generating stats for past 24 hours"

      # Process last 24 hours, hour by hour, to catch any gaps
      cursor = 24.hours.ago.beginning_of_hour
      hour_count = 0

      while cursor <= DateTime.current.beginning_of_hour
        # Users
        Statistic.generate_leadspeed(resolution: 60, time_start: cursor, time_end: cursor + 1.hour)

        # Properties
        Property.active.each do |property|
          Statistic.generate_property_leadspeed(property: property, resolution: 60, time_start: cursor, time_end: cursor + 1.hour)
        end

        # Teams
        Team.all.each do |team|
          Statistic.generate_team_leadspeed(team: team, resolution: 60, time_start: cursor, time_end: cursor + 1.hour)
        end

        cursor += 1.hour
        hour_count += 1
      end

      puts "*** Processed #{hour_count} hours"
      puts "*** Running rollups to ensure daily/weekly stats are current"

      # Run rollups for the last 2 days to ensure everything is current
      2.times do |i|
        Statistic.rollup_leadspeed(interval: :day, time_start: (i + 1).days.ago.beginning_of_day)
      end

      # Run weekly rollup for current week
      Statistic.rollup_leadspeed(interval: :week, time_start: DateTime.current.beginning_of_week)

      puts "*** Daily backfill complete"
    end
  end

  desc "Rollup Stats"
  task :rollup => :environment do
    puts "*** Rolling up all LeadSpeed Statistics"
    Statistic.rollup_all_leadspeed_intervals
    Statistic.rollup_all_tenacity_intervals
  end

  desc "Generate Stats"
  task generate: ['leadspeed:generate', 'tenacity:generate'] do
    ### Triggered statistics generation tasks
  end

  namespace :impressions do
    desc "Page Impressions"
    task by_reference: :environment do
      data = UserImpression.where(created_at: 1.month.ago..DateTime.current).select('reference as ref, count(reference) as ct').group(:reference).order('ct desc').map{|r| [r.ref, r.ct]}
      csv_data = CSV.generate do |csv|
        csv << ['Page', 'Count']
        data.each do |row|
          csv << row
        end
      end
      puts csv_data
    end
  end
end
