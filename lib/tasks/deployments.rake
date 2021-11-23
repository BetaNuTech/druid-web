namespace :post_deployment do

  desc "task20211216"
  task task2021216: :environment do
    # Backfill incoming phone lead first contact events for 6 months (`Lead.backfill_incoming_call_contact_events(time_start: )`)
    # Delete Statistics for the past 6 months
    # Backfill tenacity 6 months
    # Backfill lead speed 6 months
    # Rollup all statistics for past 6 months 

    start_date = 6.months.ago.beginning_of_month

    puts "*** Backfilling contact events from incoming calls after #{start_date}"
    Lead.backfill_incoming_call_contact_events(time_start: start_date)

    puts "*** Clearing statistics after #{start_date}"
    Statistic.where('time_start > :start_date', start_date: start_date).destroy_all

    puts "*** Backfilling tenacity stats after #{start_date}"
    Statistic.backfill_tenacity(time_start: start_date, time_end: Time.now)

    puts "*** Backfilling lead speed stats after #{start_date}"
    Statistic.backfill_leadspeed(time_start: start_date, time_end: Time.now)
  end
end
