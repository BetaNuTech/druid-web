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
#  glyph       :string
#

class LeadAction < ApplicationRecord
  ### Class Concerns/Extensions
  extend Seeds::Seedable

  ### Constants
  ALLOWED_PARAMS = [:id, :name, :glyph, :description, :active]

  ### Associations

  ### Validations
  validates :name,
    presence: true,
    uniqueness: { case_sensitive: false }

  ### Class Methods


  ### Instance Methods

  private
end
