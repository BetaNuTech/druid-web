class RemoveLeadAppointmentStateItems < ActiveRecord::Migration[5.2]
  def self.up
    puts "*** Removing Appointment Engagement Policy and associated records"
    EngagementPolicy.where(lead_state: 'appointment').last.destroy

    filename = File.join(Rails.root,"db","seeds", "engagement_policy.yml")
    puts "*** Loading New EngagementPolicy from #{filename}"
    loader = EngagementPolicyLoader.new(filename)
    loader.call
  end

  def self.down
    # NOOP
  end
end
