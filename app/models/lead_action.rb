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
  include Seeds::Seedable

  ### Constants
  ALLOWED_PARAMS = [:id, :name, :glyph, :description, :active, :is_contact]

  ### Associations

  ### Validations
  validates :name,
    presence: true,
    uniqueness: { case_sensitive: false }

  ### Callbacks
  before_destroy :check_for_use

  ### Class Methods

  ### Instance Methods

  private

  def check_for_use
    # Verify there are no dependent EngagementPolicyActions
    if EngagementPolicyAction.where(lead_action_id: self.id).any?
      errors.add(:base, "Will not delete. This Lead Action is in use by an Engagement Policy.")
      throw(:abort)
    end

    if Note.where(lead_action_id: self.id).any?
      errors.add(:base, "Will not delete. This Lead Action is in use by a Note.")
      throw(:abort)
    end
  end
end
