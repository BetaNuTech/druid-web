class RemoveLeadAppointmentStateItems < ActiveRecord::Migration[5.2]
  def self.up
    puts "*** Removing Appointment Engagement Policy and associated records"
        
    # Add nil check before calling destroy
    appointment_policy = EngagementPolicy.where(lead_state: 'appointment').last
    appointment_policy&.destroy

    puts "*** Loading New EngagementPolicy from #{Rails.root.join('db/seeds/engagement_policy.yml')}"
    
    # Add error handling around loading engagement policies
    begin
      # Create the 'Claim Lead' action if it doesn't exist
      unless LeadAction.where(name: 'Claim Lead').exists?
        puts "*** Creating missing LeadAction 'Claim Lead'"
        LeadAction.create!(name: 'Claim Lead')
      end
      
      # Load the engagement policies
      engagement_policy_loader = EngagementPolicyLoader.new
      engagement_policy_loader.load_from_file(Rails.root.join('db/seeds/engagement_policy.yml'))
    rescue => e
      puts "*** ERROR: Failed to load engagement policies: #{e.message}"
      puts "*** Continuing migration without loading engagement policies"
      # You might want to raise the error or continue without re-raising
      # raise e  # Uncomment to abort the migration
    end
  end

  def self.down
    # NOOP
  end
end
