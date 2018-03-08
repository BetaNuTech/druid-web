# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  role_id                :uuid
#  timezone               :string           default("UTC")
#

class User < ApplicationRecord

  ### Class Concerns/Extensions
  include Users::Roles
  include Users::Profile
  include Users::Devise
  include Users::PropertyAgents
  audited

  ### Constants
  ALLOWED_PARAMS = [:id, :email, :password, :password_confirmation, :role_id, :timezone]

  ### Associations
  has_many :leads

  ### Validations

  ### Class Methods

  ### Instance Methods

  def name
    if first_name.nil? && last_name.nil?
      email
    else
      [name_prefix, first_name, last_name].compact.join(' ')
    end
  end

end
