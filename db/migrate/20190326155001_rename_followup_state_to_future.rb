class RenameFollowupStateToFuture < ActiveRecord::Migration[5.2]
  def self.up
    Lead.where(state: 'followup').update_all(state: 'future')
  end
  def self.down
    Lead.where(state: 'future').update_all(state: 'followup')
  end
end
