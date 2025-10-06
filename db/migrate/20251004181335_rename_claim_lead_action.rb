class RenameClaimLeadAction < ActiveRecord::Migration[6.1]
  def up
    # Update the LeadAction name from "Claim Lead" to "Work Lead"
    # The seed file already has "Work Lead" but existing DB records may have "Claim Lead"
    if LeadAction.where(name: 'Claim Lead').exists?
      claim_action = LeadAction.find_by(name: 'Claim Lead')
      work_action = LeadAction.find_by(name: 'Work Lead')

      if work_action.nil?
        # If "Work Lead" doesn't exist, just rename the old one
        claim_action.update!(name: 'Work Lead', description: 'Work a new/open Lead')
        puts "✓ Renamed 'Claim Lead' to 'Work Lead'"
      else
        # If "Work Lead" already exists, we need to reassign scheduled actions
        # and then delete the old "Claim Lead" action
        scheduled_actions_count = ScheduledAction.where(lead_action_id: claim_action.id).count

        if scheduled_actions_count > 0
          ScheduledAction.where(lead_action_id: claim_action.id).update_all(lead_action_id: work_action.id)
          puts "✓ Reassigned #{scheduled_actions_count} scheduled actions from 'Claim Lead' to 'Work Lead'"
        end

        claim_action.destroy!
        puts "✓ Removed duplicate 'Claim Lead' action"
      end
    else
      puts "✓ No 'Claim Lead' action found - already updated"
    end

    # Update ScheduledAction descriptions that contain "Claim" terminology
    say_with_time "Updating ScheduledAction descriptions with 'Claim' terminology" do
      # Update descriptions that say "Claim a new/open Lead"
      claim_desc_count = ScheduledAction.where("description LIKE ?", "%Claim a new/open Lead%").count
      ScheduledAction.where("description LIKE ?", "%Claim a new/open Lead%")
        .update_all("description = REPLACE(description, 'Claim a new/open Lead', 'Work a new/open Lead')")

      # Update any other variations with "Claim" in the description
      claim_general_count = ScheduledAction.where("description LIKE ?", "%Claim %")
        .where.not("description LIKE ?", "%Work a new/open Lead%").count
      ScheduledAction.where("description LIKE ?", "%Claim %")
        .where.not("description LIKE ?", "%Work a new/open Lead%")
        .update_all("description = REPLACE(description, 'Claim', 'Work')")

      puts "✓ Updated #{claim_desc_count} scheduled action descriptions: 'Claim a new/open Lead' → 'Work a new/open Lead'"
      puts "✓ Updated #{claim_general_count} scheduled action descriptions: 'Claim' → 'Work'"

      claim_desc_count + claim_general_count
    end
  end

  def down
    # No rollback - we don't want to reintroduce old terminology
    puts "Cannot rollback terminology update"
  end
end
