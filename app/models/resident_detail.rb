# == Schema Information
#
# Table name: resident_details
#
#  id               :uuid             not null, primary key
#  resident_id      :uuid
#  phone1           :string
#  phone1_type      :string
#  phone1_tod       :string
#  phone2           :string
#  phone2_type      :string
#  phone2_tod       :string
#  email            :string
#  encrypted_ssn    :string
#  encrypted_ssn_iv :string
#  id_number        :string
#  id_state         :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class ResidentDetail < ApplicationRecord
  ### Class Concerns/Extensions
  attr_encrypted :ssn, key: proc { |detail| detail.crypto_key }
  audited

  ### Constants
  ALLOWED_PARAMS = [:id, :resident_id, :phone1, :phone1_type, :phone1_tod, :phone2, :phone2_type, :phone2_tod, :email, :ssn, :id_number, :id_state ]
  DEFAULT_CRYPTO_KEY = 'default-crypto-key-default-crypto-key'
  PHONE_TYPES = ["Cell", "Home", "Work"]
  PHONE_TOD = [ "Any Time", "Morning", "Afternoon", "Evening"]

  ### Associations
  belongs_to :resident

  ### Validations
  # None

  ### Class Methods

  ### Instance Methods

  def crypto_key
    unless (key = ENV.fetch('CRYPTO_KEY', nil)).present?
      key = DEFAULT_CRYPTO_KEY
      err_message = "ERROR: ENV[CRYPTO_KEY] is not set!!! Defaulting to '#{key}'"
      Rails.logger.error err_message
    end
    # Key must be 32 characters
    return ( key + '0'*32  )[0..31]
  end
end
