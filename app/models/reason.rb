# == Schema Information
#
# Table name: reasons
#
#  id          :uuid             not null, primary key
#  name        :string
#  description :string
#  active      :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Reason < ApplicationRecord
  ALLOWED_PARAMS = [:id, :name, :description, :active]

  validates :name,
    presence: true,
    uniqueness: { case_sensitive: false }

  scope :active, -> {where(active: true)}

end
