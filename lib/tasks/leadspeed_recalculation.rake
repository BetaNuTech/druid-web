namespace :leadspeed do
  desc "Recalculate lead_time for existing contact events using business hours logic (active properties only)"
  task :recalculate_business_hours => :environment do
    puts "=" * 80
    puts "Lead Speed Recalculation: Business Hours Logic"
    puts "=" * 80
    puts ""
    puts "This task will:"
    puts "  1. Recalculate lead_time for all first contact events"
    puts "  2. Only process leads from ACTIVE properties"
    puts "  3. Skip phone-sourced leads (already 0 minutes)"
    puts "  4. Apply business hours logic to all other leads"
    puts "  5. Regenerate lead speed statistics"
    puts ""
    puts "=" * 80
    puts ""

    # Get active properties
    active_properties = Property.active.to_a
    puts "Found #{active_properties.count} active properties"
    puts ""

    # Get all first contact events for leads in active properties
    contact_events = ContactEvent.joins(:lead)
                                 .where(first_contact: true)
                                 .where(leads: { property_id: active_properties.map(&:id) })
                                 .includes(:lead)

    total_events = contact_events.count
    puts "Found #{total_events} first contact events to process"
    puts ""

    if total_events == 0
      puts "No contact events to process. Exiting."
      exit
    end

    # Ask for confirmation
    print "Proceed with recalculation? (yes/no): "
    confirmation = STDIN.gets.chomp.downcase

    unless confirmation == 'yes'
      puts "Recalculation cancelled."
      exit
    end

    puts ""
    puts "Starting recalculation..."
    puts ""

    updated_count = 0
    skipped_phone_count = 0
    skipped_no_property_count = 0
    error_count = 0
    unchanged_count = 0

    contact_events.find_each.with_index do |event, index|
      begin
        lead = event.lead

        # Skip if no lead (shouldn't happen but safety check)
        if lead.nil?
          skipped_no_property_count += 1
          next
        end

        # Skip if no property (shouldn't happen since we filtered above)
        if lead.property.nil?
          skipped_no_property_count += 1
          next
        end

        # Skip phone-sourced leads (they should always be 0)
        if lead.source&.phone_source? && event.lead_time == 0
          skipped_phone_count += 1
          next
        end

        # Calculate new lead time using business hours logic
        old_lead_time = event.lead_time
        new_lead_time = lead.contact_lead_time(true, event.timestamp)

        if old_lead_time == new_lead_time
          unchanged_count += 1
        else
          # Update the contact event with new lead_time
          event.update_column(:lead_time, new_lead_time)
          updated_count += 1

          # Log significant changes (> 60 minutes difference)
          if (old_lead_time - new_lead_time).abs > 60
            puts "  Lead #{lead.id}: #{old_lead_time} min → #{new_lead_time} min (#{old_lead_time - new_lead_time} min difference)"
          end
        end

      rescue => e
        error_count += 1
        puts "  ERROR processing contact event #{event.id}: #{e.message}"
      end

      # Progress update every 100 records
      if (index + 1) % 100 == 0
        puts "  Processed #{index + 1}/#{total_events} events..."
      end
    end

    puts ""
    puts "=" * 80
    puts "Recalculation Complete!"
    puts "=" * 80
    puts "Total events processed:     #{total_events}"
    puts "Updated:                    #{updated_count}"
    puts "Unchanged:                  #{unchanged_count}"
    puts "Skipped (phone-sourced):    #{skipped_phone_count}"
    puts "Skipped (no property):      #{skipped_no_property_count}"
    puts "Errors:                     #{error_count}"
    puts "=" * 80
    puts ""

    if updated_count > 0
      puts "Next step: Regenerate statistics"
      puts ""
      puts "Run one of these commands to regenerate statistics:"
      puts "  1. For past 2 months:  rake statistics:leadspeed:regenerate_recent"
      puts "  2. For past month:     rake statistics:leadspeed:regenerate_month"
      puts ""
      puts "Or you can run the regeneration now:"
      print "Regenerate statistics now? (yes/no): "
      regen_confirmation = STDIN.gets.chomp.downcase

      if regen_confirmation == 'yes'
        puts ""
        puts "Regenerating lead speed statistics for the past 2 months..."

        # Delete existing leadspeed statistics for the past 2 months
        time_start = 2.months.ago.beginning_of_month
        deleted_count = Statistic.where(
          fact: 'leadspeed',
          time_start: time_start..DateTime.current
        ).delete_all
        puts "  Deleted #{deleted_count} existing leadspeed statistics"

        # Regenerate hourly statistics
        puts "  Generating hourly statistics for users..."
        Statistic.generate_leadspeed(resolution: 60, time_start: time_start)

        puts "  Generating hourly statistics for active properties..."
        Property.active.each { |property|
          Statistic.generate_property_leadspeed(property: property, resolution: 60, time_start: time_start)
        }

        puts "  Generating hourly statistics for teams..."
        Team.all.each { |team|
          Statistic.generate_team_leadspeed(team: team, resolution: 60, time_start: time_start)
        }

        # Rollup to daily, weekly, monthly
        puts "  Rolling up to daily statistics..."
        61.times { |i| Statistic.rollup_leadspeed(interval: :day, time_start: Statistic.utc_day_start - (i+1).days) }

        puts "  Rolling up to weekly statistics..."
        9.times { |i| Statistic.rollup_leadspeed(interval: :week, time_start: Statistic.utc_day_start - (i+1).weeks) }

        puts "  Rolling up to monthly statistics..."
        2.times { |i| Statistic.rollup_leadspeed(interval: :month, time_start: Statistic.utc_month_start - (i+1).months) }

        puts ""
        puts "Statistics regeneration complete!"
      else
        puts "Statistics regeneration skipped."
      end
    end

    puts ""
    puts "Done!"
  end

  desc "Regenerate lead speed statistics for the past 2 months (for active properties)"
  task :regenerate_recent => :environment do
    puts "Regenerating lead speed statistics for the past 2 months..."

    time_start = 2.months.ago.beginning_of_month

    # Delete existing statistics
    deleted_count = Statistic.where(
      fact: 'leadspeed',
      time_start: time_start..DateTime.current
    ).delete_all
    puts "Deleted #{deleted_count} existing leadspeed statistics"

    # Regenerate hourly statistics
    puts "Generating hourly statistics for users..."
    Statistic.generate_leadspeed(resolution: 60, time_start: time_start)

    puts "Generating hourly statistics for active properties..."
    Property.active.each { |property|
      Statistic.generate_property_leadspeed(property: property, resolution: 60, time_start: time_start)
    }

    puts "Generating hourly statistics for teams..."
    Team.all.each { |team|
      Statistic.generate_team_leadspeed(team: team, resolution: 60, time_start: time_start)
    }

    # Rollup
    puts "Rolling up to daily statistics..."
    61.times { |i| Statistic.rollup_leadspeed(interval: :day, time_start: Statistic.utc_day_start - (i+1).days) }

    puts "Rolling up to weekly statistics..."
    9.times { |i| Statistic.rollup_leadspeed(interval: :week, time_start: Statistic.utc_day_start - (i+1).weeks) }

    puts "Rolling up to monthly statistics..."
    2.times { |i| Statistic.rollup_leadspeed(interval: :month, time_start: Statistic.utc_month_start - (i+1).months) }

    puts "Statistics regeneration complete!"
  end

  desc "Regenerate lead speed statistics for the past month (for active properties)"
  task :regenerate_month => :environment do
    puts "Regenerating lead speed statistics for the past month..."

    time_start = 1.month.ago.beginning_of_month

    # Delete existing statistics
    deleted_count = Statistic.where(
      fact: 'leadspeed',
      time_start: time_start..DateTime.current
    ).delete_all
    puts "Deleted #{deleted_count} existing leadspeed statistics"

    # Regenerate hourly statistics
    puts "Generating hourly statistics for users..."
    Statistic.generate_leadspeed(resolution: 60, time_start: time_start)

    puts "Generating hourly statistics for active properties..."
    Property.active.each { |property|
      Statistic.generate_property_leadspeed(property: property, resolution: 60, time_start: time_start)
    }

    puts "Generating hourly statistics for teams..."
    Team.all.each { |team|
      Statistic.generate_team_leadspeed(team: team, resolution: 60, time_start: time_start)
    }

    # Rollup
    puts "Rolling up to daily statistics..."
    32.times { |i| Statistic.rollup_leadspeed(interval: :day, time_start: Statistic.utc_day_start - (i+1).days) }

    puts "Rolling up to weekly statistics..."
    5.times { |i| Statistic.rollup_leadspeed(interval: :week, time_start: Statistic.utc_day_start - (i+1).weeks) }

    puts "Rolling up to monthly statistics..."
    Statistic.rollup_leadspeed(interval: :month, time_start: Statistic.utc_month_start - 1.month)

    puts "Statistics regeneration complete!"
  end
end
