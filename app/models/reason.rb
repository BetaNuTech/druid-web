# == Schema Information
#
# Table name: reasons
#
#  id          :uuid             not null, primary key
#  name        :string
#  description :string
#  active      :boolean          default("true")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Reason < ApplicationRecord
  ### class concerns/extensions
  audited
  include Seeds::Seedable

  ### Constants
  ALLOWED_PARAMS = [:id, :name, :description, :active]

  ### Validations
  validates :name,
    presence: true,
    uniqueness: { case_sensitive: false }

  ### Scopes
  scope :active, -> {where(active: true)}

end
