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
#

class User < ApplicationRecord

  ### Class Concerns/Extensions
  include Users::Roles
  include Users::Devise
  audited

  ### Constants
  ALLOWED_PARAMS = [:id, :email, :password, :password_confirmation, :role_id]
  devise :database_authenticatable, :lockable, :timeoutable, :confirmable, :recoverable, :rememberable, :trackable, :validatable

  ### Associations
  has_many :property_agents, dependent: :destroy
  accepts_nested_attributes_for :property_agents
  has_many :properties, through: :property_agents

  ### Validations

  ### Class Methods

  ### Instance Methods

  def name
    email
  end

end
