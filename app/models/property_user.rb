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

  ### Callbacks
  before_destroy :reassign_pending_tasks

  ### Constants
  ALLOWED_PARAMS = [:id, :user_id, :property_id, :role, :_destroy]
  AGENT_ROLE = 'agent'
  MANAGER_ROLE = 'manager'

  ### Enums
  enum role: { AGENT_ROLE => 0, MANAGER_ROLE => 1}

  ### Validations
  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :property_id }

  ### Scopes
  scope :management_assignments, -> { where(role: MANAGER_ROLE)}
  scope :agent_assignments, -> { where(role: AGENT_ROLE)}

  ### Public methods

  def agent?
    role == AGENT_ROLE
  end

  def manager?
    role == MANAGER_ROLE
  end

  private

  def reassign_pending_tasks
    new_user = property.primary_agent
    pending_tasks = user.tasks_pending
    pending_tasks.select{|task|
      task.state == 'pending' &&
        task.target&.property_id == property_id
    }.each{|task| task.user_id = new_user.id; task.save}
  end

end
