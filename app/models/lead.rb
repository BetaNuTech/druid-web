# == Schema Information
#
# Table name: leads
#
#  id             :uuid             not null, primary key
#  user_id        :uuid
#  lead_source_id :uuid
#  title          :string
#  first_name     :string
#  last_name      :string
#  referral       :string
#  state          :string
#  notes          :text
#  first_comm     :datetime
#  last_comm      :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  property_id    :uuid
#  phone1         :string
#  phone2         :string
#  fax            :string
#  email          :string
#

class Lead < ApplicationRecord

  ### Class Concerns/Extensions
  include Leads::StateMachine
  audited

  ### Constants
  ALLOWED_PARAMS = [:lead_source_id, :property_id, :title, :first_name, :last_name, :referral, :state, :notes, :first_comm, :last_comm, :phone1, :phone2, :email, :fax, :user_id]

  ### Associations
  has_one :preference,
    class_name: 'LeadPreference',
    dependent: :destroy
  accepts_nested_attributes_for :preference
  belongs_to :source, class_name: 'LeadSource', foreign_key: 'lead_source_id', required: false
  belongs_to :property, required: false
  belongs_to :user, required: false

  ### Validations
  validates :first_name, presence: true
	validates :phone1, presence: true, unless: ->(lead){ lead.phone2.present? || lead.email.present? }
	validates :email, presence: true, unless: ->(lead){ lead.phone1.present? || lead.phone2.present? }

  ### Class Methods

  ### Instance Methods
  def name
    [title, first_name, last_name].join(' ')
  end

  private

end
