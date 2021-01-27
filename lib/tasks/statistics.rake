namespace :statistics do

  desc "Bootstrap Statistics and LeadSpeed"
  task :bootstrap => :environment do
    time_basis = Time.now.utc.beginning_of_day
    two_months_ago = time_basis.beginning_of_month - 2.months

    if ContactEvent.count < 100
      puts "*** Generating contact events for the past 2 months"
      Lead.where(created_at: two_months_ago..Time.now).each do |lead|
        messages = lead.messages.outgoing.where(classification: 'default').to_a
        tasks = lead.scheduled_actions.contact.completed.to_a
        (messages + tasks).sort_by(&:created_at).each do |article|
          begin
            case article
            when Message
              next if article.for_compliance?
              article.messageable.create_contact_event_without_delay(
                timestamp: article.delivered_at,
                description: 'Historical contact event for message',
                article: article
              )
            when ScheduledAction
              article.target.create_contact_event_without_delay(
                timestamp: article.completed_at,
                description: 'Historical contact event for task',
                article: article
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
      Statistic.generate_leadspeed(resolution: 60, time_start: Statistic.utc_hour_start - 2.hours)

      puts "*** Generating Property LeadSpeed Statistics for the past 2 hours"
      Property.active.each{|property| Statistic.generate_property_leadspeed(property: property, resolution: 60, time_start: Statistic.utc_hour_start - 2.hours)}

      puts "*** Generating Team LeadSpeed Statistics for the past 2 hours"
      Team.all.each{|team| Statistic.generate_team_leadspeed(team: team, resolution: 60, time_start: Statistic.utc_hour_start - 2.hours)}
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
end
