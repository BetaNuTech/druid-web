namespace :statistics do

  desc "Bootstrap Statistics and LeadSpeed"
  task :bootstrap => :environment do
    if ContactEvent.count < 100
      puts "*** Generating contact events for the past 3 months"
      Lead.where(created_at: 3.months.ago..Time.now).each do |lead|
        messages = lead.messages.outgoing.where(classification: 'default').to_a
        tasks = lead.scheduled_actions.contact.completed.to_a
        (messages + tasks).sort_by(&:created_at).each do |article|
          case article
          when Message
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
        end
      end
    end

    puts "*** Generating Leadspeed for the past 3 months"
    Statistic.generate_leadspeed(resolution: 60, time_start: 3.months.ago.beginning_of_month)

    puts "*** Generating Property Leadspeed for the past 3 months"
    Property.active.each{|property| Statistic.generate_property_leadspeed(property: property, resolution: 60, time_start: 3.months.ago.beginning_of_month)}

    puts "*** Generating Property Leadspeed for the past 3 months"
    Team.all.each{|team| Statistic.generate_team_leadspeed(team: team, resolution: 60, time_start: 3.months.ago.beginning_of_month)}

    puts "*** Rolling up Leadspeed by day for the past 3 months"
    120.times{|i| Statistic.rollup_leadspeed(interval: :day, time_start: (i+1).days.ago.beginning_of_day)}

    puts "*** Rolling up Leadspeed by week for the past 3 months"
    12.times{|i| Statistic.rollup_leadspeed(interval: :week, time_start: (i+1).weeks.ago.beginning_of_week)}

    puts "*** Rolling up Leadspeed by week for the past 3 months"
    3.times{|i| Statistic.rollup_leadspeed(interval: :month, time_start: (i+1).months.ago.beginning_of_month)}
  end

  namespace :leadspeed do
    desc "generate leadspeed hourly statistics"
    task :generate => :environment do
      puts "*** Generating LeadSpeed Statistics for the past 2 hours"
      Statistic.generate_leadspeed(resolution: 60, time_start: 2.hours.ago)

      puts "*** Generating Property LeadSpeed Statistics for the past 2 hours"
      Property.active.each{|property| Statistic.generate_property_leadspeed(property: property, resolution: 60, time_start: 2.hours.ago)}

      puts "*** Generating Team LeadSpeed Statistics for the past 2 hours"
      Team.all.each{|team| Statistic.generate_team_leadspeed(team: team, resolution: 60, time_start: 2.hours.ago)}
    end

    desc "Rollup Leadspeed Stats"
    task :rollup => :environment do
      puts "*** Rolling up all LeadSpeed Statistics"
      Statistic.rollup_all_leadspeed_intervals
    end
  end

end
