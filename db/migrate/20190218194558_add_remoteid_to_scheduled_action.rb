class AddRemoteidToScheduledAction < ActiveRecord::Migration[5.2]
  def change
    add_column :scheduled_actions, :remoteid, :string
  end
end
