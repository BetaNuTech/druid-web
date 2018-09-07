# == Schema Information
#
# Table name: team_users
#
#  id          :uuid             not null, primary key
#  team_id     :uuid
#  user_id     :uuid
#  teamrole_id :uuid
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class TeamUser < ApplicationRecord
  ### Class Concerns/Extensions
  audited

  ### Constants
  ALLOWED_PARAMS = [:id, :team_id, :user_id, :teamrole_id, :_destroy]

  ### Validations
  validates :user_id, uniqueness: true

  ### Associations
  belongs_to :user
  belongs_to :team
  belongs_to :teamrole, optional: true

end
