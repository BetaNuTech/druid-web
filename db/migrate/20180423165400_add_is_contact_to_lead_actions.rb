class AddIsContactToLeadActions < ActiveRecord::Migration[5.1]
  def change
    add_column :lead_actions, :is_contact, :boolean, default: false
  end
end
