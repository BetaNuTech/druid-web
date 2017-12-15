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
#

class Lead < ApplicationRecord
  ALLOWED_PARAMS = [:lead_source_id, :property_id, :title, :first_name, :last_name, :referral, :state, :notes, :first_comm, :last_comm]

  ### Associations
  has_one :preference,
    class_name: 'LeadPreference',
    dependent: :destroy
  accepts_nested_attributes_for :preference
  belongs_to :source, class_name: 'LeadSource', foreign_key: 'lead_source_id', required: false
  belongs_to :property, required: false

  # TODO: Agent association

  ### Validations
  validates :first_name,
            :last_name,
    presence: true

  ### Class Methods

  ### Instance Methods
  def name
    [title, first_name, last_name].join(' ')
  end


  private

  ### Private Methods
end
