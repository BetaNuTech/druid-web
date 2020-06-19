# == Schema Information
#
# Table name: property_listings
#
#  id          :uuid             not null, primary key
#  code        :string
#  description :string
#  property_id :uuid
#  source_id   :uuid
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class PropertyListing < ApplicationRecord
  ALLOWED_PARAMS = [:id, :property_id, :source_id, :code, :description, :active]
  audited

  ## Associations
  belongs_to :property
  belongs_to :source, class_name: 'LeadSource'
  has_many :leads, through: :property

  ## Validations
  validates :code, presence: true, uniqueness: {scope: :source_id}
  validates :source_id, uniqueness: { scope: :property_id }

  ## Scopes
  scope :active, -> { where(active: true) }

  ## Class Methods

  ## Instance Methods

end
