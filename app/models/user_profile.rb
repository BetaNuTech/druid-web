# == Schema Information
#
# Table name: user_profiles
#
#  id                   :uuid             not null, primary key
#  user_id              :uuid
#  name_prefix          :string
#  first_name           :string
#  last_name            :string
#  name_suffix          :string
#  slack                :string
#  cell_phone           :string
#  office_phone         :string
#  fax                  :string
#  notes                :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  signature            :text
#  signature_enabled    :boolean          default(FALSE)
#  monitor_all_messages :boolean          default(FALSE)
#  enabled_features     :jsonb
#

class UserProfile < ApplicationRecord

  ### Class Concerns/Extensions
  audited
  include UserProfiles::Features
  include UserProfiles::Photo

  ### Constants
  ALLOWED_PARAMS = [ :id, :user_id, :name_prefix, :first_name, :last_name, :name_suffix, :slack, :cell_phone, :office_phone, :fax, :notes, :signature, :signature_enabled, :monitor_all_messages, :photo, :remove_photo].freeze

  ### Associations
  belongs_to :user, required: false

  ### Validations

  ### Class Methods

  ### Instance Methods

  def use_signature?
    signature.present? && signature_enabled?
  end
end
