class RemoveMoveinLeadState < ActiveRecord::Migration[6.1]
  def change
    Lead.where(state: :movein).update_all(state: :resident)
    EngagementPolicy.where(description: "Global Engagement Policy for 'movein' Leads").destroy_all
  end
end
