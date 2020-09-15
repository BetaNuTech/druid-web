# == Schema Information
#
# Table name: user_profiles
#
#  id               :uuid             not null, primary key
#  user_id          :uuid
#  name_prefix      :string
#  first_name       :string
#  last_name        :string
#  name_suffix      :string
#  slack            :string
#  cell_phone       :string
#  office_phone     :string
#  fax              :string
#  notes            :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  signature        :text
#  enabled_features :jsonb
#  appsettings      :jsonb
#

class UserProfile < ApplicationRecord

  ### Class Concerns/Extensions
  audited
  include UserProfiles::Features
  include UserProfiles::Appsettings
  include UserProfiles::Photo

  ### Constants
  ALLOWED_PARAMS = [ :id, :user_id, :name_prefix, :first_name, :last_name, :name_suffix, :slack, :cell_phone, :office_phone, :fax, :notes, :signature, :photo, :remove_photo].freeze

  ### Associations
  belongs_to :user, required: false

  ### Validations

  ### Class Methods

  ### Instance Methods

  def use_signature?
    signature.present? && setting_enabled?(:message_signature)
  end
end
