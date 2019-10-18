class AddNotifyToLeadActions < ActiveRecord::Migration[6.0]
  def change
    add_column :lead_actions, :notify, :boolean, default: false
  end
end
