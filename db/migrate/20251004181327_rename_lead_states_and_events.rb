class RenameLeadStatesAndEvents < ActiveRecord::Migration[6.1]
  def up
    # Update lead states
    say_with_time "Updating lead states from 'disqualified' to 'invalidated'" do
      Lead.where(state: 'disqualified').update_all(state: 'invalidated')
    end

    say_with_time "Updating lead states from 'abandoned' to 'future'" do
      # Smart scheduling: spread out follow-ups per property, max 50 per day
      abandoned_leads = Lead.includes(:property).where(state: 'abandoned')
      abandoned_count = abandoned_leads.count
      leads_per_day = 50
      base_days_out = 90

      total_properties = 0
      total_batches = 0
      property_summaries = []

      # Group by property and process each property's leads
      abandoned_leads.group_by(&:property_id).each do |property_id, property_leads|
        property = property_leads.first&.property
        property_name = property&.name || "Property #{property_id || 'None'}"
        property_status = property&.active? ? 'Active' : 'Inactive'

        # Sort by created_at DESC (most recent first)
        sorted_leads = property_leads.sort_by { |lead| lead.created_at }.reverse

        puts "  Processing #{sorted_leads.count} abandoned leads for #{property_name} (#{property_status})"

        property_batch_count = 0

        # Schedule in batches of 50 per day
        sorted_leads.each_slice(leads_per_day).with_index do |lead_batch, batch_index|
          # Set to 8am NYC time (Eastern Time)
          follow_up_date = (Date.current + (base_days_out + batch_index).days).in_time_zone('America/New_York').change(hour: 8)

          lead_batch.each do |lead|
            lead.update_columns(
              state: 'future',
              follow_up_at: follow_up_date
            )

            Note.create(
              notable: lead,
              classification: 'system',
              content: "Lead state migrated from 'abandoned' to 'future' as part of state system update. Follow-up scheduled for #{follow_up_date.to_date} (batch #{batch_index + 1}).",
              lead_action: LeadAction.find_by(name: 'State Transition'),
              reason: Reason.find_by(name: 'Pipeline Event')
            )
          end

          puts "    Batch #{batch_index + 1}: #{lead_batch.count} leads scheduled for #{follow_up_date.to_date}"
          property_batch_count += 1
          total_batches += 1
        end

        property_summaries << "#{property_name}: #{sorted_leads.count} leads in #{property_batch_count} batches"
        total_properties += 1
      end

      puts "\n  ===== Migration Summary ====="
      puts "  Total abandoned leads migrated: #{abandoned_count}"
      puts "  Properties processed: #{total_properties}"
      puts "  Total batches created: #{total_batches}"
      puts "  Leads per day limit: #{leads_per_day}"
      puts "  Follow-ups start: #{base_days_out} days from now"
      puts "  Follow-ups end: #{base_days_out + total_batches - 1} days from now"
      puts "\n  Property breakdown:"
      property_summaries.each { |summary| puts "    - #{summary}" }
      puts "  ============================="

      abandoned_count
    end

    # Update lead_transitions table
    say_with_time "Updating lead_transitions states" do
      LeadTransition.where(last_state: 'disqualified').update_all(last_state: 'invalidated')
      LeadTransition.where(current_state: 'disqualified').update_all(current_state: 'invalidated')

      LeadTransition.where(last_state: 'abandoned').update_all(last_state: 'future')
      LeadTransition.where(current_state: 'abandoned').update_all(current_state: 'future')
    end

    # Update classifications if stored separately
    say_with_time "Ensuring lead classifications are preserved" do
      # Classifications are separate from states, so no changes needed
      # Just logging for clarity
      Lead.where(state: 'invalidated').group(:classification).count
    end
  end

  def down
    # Reverse the migration
    say_with_time "Reverting lead states from 'invalidated' to 'disqualified'" do
      Lead.where(state: 'invalidated').update_all(state: 'disqualified')
    end

    say_with_time "Reverting lead states from 'future' with migration notes to 'abandoned'" do
      # Find leads that were migrated from abandoned to future
      migrated_lead_ids = Note.where(
        classification: 'system',
        content: Note.arel_table[:content].matches("Lead state migrated from 'abandoned' to 'future' as part of state system update%")
      ).pluck(:notable_id)

      Lead.where(id: migrated_lead_ids, state: 'future').update_all(state: 'abandoned', follow_up_at: nil)
    end

    # Revert lead_transitions table
    say_with_time "Reverting lead_transitions states" do
      LeadTransition.where(last_state: 'invalidated').update_all(last_state: 'disqualified')
      LeadTransition.where(current_state: 'invalidated').update_all(current_state: 'disqualified')

      # Note: We can't perfectly reverse abandoned/future transitions without more data
      # This is a best-effort rollback
    end
  end
end
