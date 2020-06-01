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
  FIRST_CONTACT_REASON = 'First Contact'

  ### Validations
  validates :name,
    presence: true,
    uniqueness: { case_sensitive: false }

  ### Scopes
  scope :active, -> {where(active: true)}

  def self.first_contact
    if (record = self.active.where(name: FIRST_CONTACT_REASON).first).present?
      return record
    else
      err_msg = 'Reason with Name "First Contact" is missing!'
      ErrorNotification.send(StandardError.new(err_msg))
      return nil
    end
  end

end
