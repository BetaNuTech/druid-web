# == Schema Information
#
# Table name: leads
#
#  id             :uuid             not null, primary key
#  user_id        :uuid
#  lead_source_id :uuid
#  title          :string
#  first_name     :string
#  last_name      :string
#  referral       :string
#  state          :string
#  notes          :text
#  first_comm     :datetime
#  last_comm      :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Lead < ApplicationRecord
  validates :first_name,
            :last_name,
    presence: true
  has_one :preference,
    class_name: 'LeadPreference',
    dependent: :destroy

  def name
    [title, first_name, last_name].join(' ')
  end
end
