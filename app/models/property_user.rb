# == Schema Information
#
# Table name: property_users
#
#  id          :uuid             not null, primary key
#  property_id :uuid
#  user_id     :uuid
#  role        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class PropertyUser < ApplicationRecord

  ### Associations
  belongs_to :property
  belongs_to :user

  ### Constants
  ALLOWED_PARAMS = [:id, :user_id, :property_id, :role, :_destroy]
  AGENT_ROLE = 'agent'
  MANAGER_ROLE = 'manager'

  ### Enums
  enum role: { AGENT_ROLE => 0, MANAGER_ROLE => 1}

  ### Validations
  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :property_id }

  ### Public methods

  def agent?
    role == AGENT_ROLE
  end

  def manager?
    role == MANAGER_ROLE
  end

end
