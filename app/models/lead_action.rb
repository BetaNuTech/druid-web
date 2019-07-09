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
#  is_contact  :boolean          default(FALSE)
#

class LeadAction < ApplicationRecord
  ### class concerns/extensions
  audited
  include Seeds::Seedable

  ### Constants
  ALLOWED_PARAMS = [:id, :name, :glyph, :description, :active, :is_contact]
  SHOWING_ACTION_NAME = 'Show Unit'

  ### Associations

  ### Scopes
  scope :active, -> {where(active: true)}

  ### Validations
  validates :name,
    presence: true,
    uniqueness: { case_sensitive: false }

  ### Callbacks
  before_destroy :check_for_use

  ### Class Methods

  def self.showing
    if (record = self.active.where(name: SHOWING_ACTION_NAME).first).present?
      return record
    else
      err_msg = 'LeadAction with Name "Show Unit" is missing!'
      ErrorNotification.send(StandardError.new(err_msg))
      return nil
    end
  end

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
