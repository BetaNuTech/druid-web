class RenameLeadStatesAndEvents < ActiveRecord::Migration[6.1]
  def up
    # Update lead states - simple and fast
    say_with_time "Updating lead states from 'disqualified' to 'invalidated'" do
      Lead.where(state: 'disqualified').update_all(state: 'invalidated')
    end

    say_with_time "Updating lead states from 'abandoned' to 'future'" do
      total_abandoned = 0
      total_properties = 0
      base_days_out = 90
      leads_per_day = 50

      # Look up LeadAction and Reason once for all notes
      lead_action = LeadAction.find_by(name: 'State Transition')
      reason = Reason.find_by(name: 'Pipeline Event')
      lead_action_id = lead_action&.id
      reason_id = reason&.id

      # Get all unique property IDs for abandoned leads
      property_ids = Lead.where(state: 'abandoned').distinct.pluck(:property_id)

      puts "  Processing #{property_ids.count} properties with abandoned leads..."

      property_ids.each do |property_id|
        property_abandoned_count = 0
        property = Property.find_by(id: property_id)
        property_name = property&.name || "Property #{property_id || 'None'}"

        # Array to accumulate note attributes for bulk insert
        notes_to_insert = []

        # Process this property's abandoned leads in batches
        Lead.where(state: 'abandoned', property_id: property_id).find_in_batches(batch_size: 100) do |batch|
          batch.each do |lead|
            # Each property starts fresh at 90 days out
            # First 50 leads → 90 days, next 50 → 91 days, etc.
            days_offset = (property_abandoned_count / leads_per_day)
            follow_up_date = (Date.current + (base_days_out + days_offset).days).in_time_zone('America/New_York').change(hour: 8)

            lead.update_columns(
              state: 'future',
              follow_up_at: follow_up_date
            )

            # Add note attributes for bulk insert
            batch_number = (property_abandoned_count / leads_per_day) + 1
            notes_to_insert << {
              notable_id: lead.id,
              notable_type: 'Lead',
              classification: 'system',
              content: "Lead state migrated from 'abandoned' to 'future' as part of state system update. Follow-up scheduled for #{follow_up_date.to_date} (batch #{batch_number}).",
              lead_action_id: lead_action_id,
              reason_id: reason_id,
              created_at: Time.current,
              updated_at: Time.current
            }

            property_abandoned_count += 1
            total_abandoned += 1
          end

          # Bulk insert every 1000 notes to keep memory low
          if notes_to_insert.size >= 1000
            Note.insert_all(notes_to_insert) if notes_to_insert.any?
            notes_to_insert = []
          end
        end

        # Insert any remaining notes for this property
        Note.insert_all(notes_to_insert) if notes_to_insert.any?

        # Log per-property summary
        batches = (property_abandoned_count.to_f / leads_per_day).ceil
        puts "    #{property_name}: #{property_abandoned_count} leads in #{batches} batch(es)"
        total_properties += 1
      end

      puts "\n  ===== Migration Summary ====="
      puts "  Total abandoned leads migrated: #{total_abandoned}"
      puts "  Properties processed: #{total_properties}"
      puts "  Leads per day per property: #{leads_per_day}"
      puts "  Each property starts at: #{base_days_out} days from now"
      puts "  ============================="

      total_abandoned
    end

    # Update lead_transitions table
    say_with_time "Updating lead_transitions states" do
      LeadTransition.where(last_state: 'disqualified').update_all(last_state: 'invalidated')
      LeadTransition.where(current_state: 'disqualified').update_all(current_state: 'invalidated')

      LeadTransition.where(last_state: 'abandoned').update_all(last_state: 'future')
      LeadTransition.where(current_state: 'abandoned').update_all(current_state: 'future')
    end
  end

  def down
    # Reverse the migration
    say_with_time "Reverting lead states from 'invalidated' to 'disqualified'" do
      Lead.where(state: 'invalidated').update_all(state: 'disqualified')
    end

    say_with_time "Reverting lead states from 'future' to 'abandoned'" do
      # Find and revert leads that were migrated (have the migration note)
      migrated_lead_ids = Note.where(
        classification: 'system',
        notable_type: 'Lead'
      ).where("content LIKE ?", "Lead state migrated from 'abandoned' to 'future'%")
        .pluck(:notable_id)

      Lead.where(id: migrated_lead_ids, state: 'future').update_all(state: 'abandoned', follow_up_at: nil)

      # Delete the migration notes
      Note.where(
        classification: 'system',
        notable_type: 'Lead'
      ).where("content LIKE ?", "Lead state migrated from 'abandoned' to 'future'%").delete_all
    end

    # Revert lead_transitions table
    say_with_time "Reverting lead_transitions states" do
      LeadTransition.where(last_state: 'invalidated').update_all(last_state: 'disqualified')
      LeadTransition.where(current_state: 'invalidated').update_all(current_state: 'disqualified')

      LeadTransition.where(last_state: 'future').update_all(last_state: 'abandoned')
      LeadTransition.where(current_state: 'future').update_all(current_state: 'abandoned')
    end
  end
end
