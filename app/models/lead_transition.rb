# == Schema Information
#
# Table name: lead_transitions
#
#  id             :uuid             not null, primary key
#  lead_id        :uuid             not null
#  last_state     :string           not null
#  current_state  :string           not null
#  classification :integer
#  memo           :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class LeadTransition < ApplicationRecord
  ### Class Concerns/Extensions

  ### Constants

  ### Enums
  enum classification: { lead: 0, vendor: 1, resident: 2, duplicate: 3, other: 4 }

  ### Attributes
  validates :last_state, :current_state, presence: true

  ### Associations
  belongs_to :lead
end