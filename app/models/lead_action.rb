# == Schema Information
#
# Table name: lead_actions
#
#  id          :uuid             not null, primary key
#  name        :string
#  description :string
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class LeadAction < ApplicationRecord
  ALLOWED_PARAMS = [:id, :name, :glyph, :description, :active]

  validates :name,
    presence: true,
    uniqueness: { case_sensitive: false }
end
