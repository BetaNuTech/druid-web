# == Schema Information
#
# Table name: units
#
#  id             :uuid             not null, primary key
#  property_id    :uuid
#  unit_type_id   :uuid
#  rental_type_id :uuid
#  unit           :string
#  floor          :integer
#  sqft           :integer
#  bedrooms       :integer
#  description    :text
#  address1       :string
#  address2       :string
#  city           :string
#  state          :string
#  zip            :string
#  country        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  remoteid       :string
#  bathrooms      :integer
#  occupancy      :string           default("vacant")
#  lease_status   :string           default("available")
#  available_on   :date
#  market_rent    :decimal(, )      default(0.0)
#

class Unit < ApplicationRecord
  ### Constants
  ALLOWED_PARAMS = [:id, :property_id, :unit_type_id, :rental_type_id, :unit, :floor, :sqft, :bedrooms, :address1, :address2, :city, :state, :zipcode, :country, :bathrooms, :occupancy, :lease_status, :available_on, :market_rent]
  OCCUPANCY_STATUSES = ['occupied', 'vacant']
  LEASE_STATUSES = ['available', 'leased', 'leased_reserved', 'on_notice', 'other', 'nosale']

  ### Class Concerns/Extensions
  audited

  ### Associations
  belongs_to :property
  belongs_to :rental_type
  belongs_to :unit_type
  has_one :resident
  delegate :name, to: :property, prefix: true
  delegate :name, to: :unit_type, prefix: true
  delegate :name, to: :rental_type, prefix: true

  ### Validations
  validates :lease_status, inclusion: { in: LEASE_STATUSES }
  validates :market_rent, numericality: { greater_than_or_equal_to: 0.0 }
  validates :occupancy, inclusion: { in: OCCUPANCY_STATUSES }
  validates :remoteid, uniqueness: { case_sensitive: false, scope: :property_id }, if: Proc.new{|unit| unit.remoteid.present? }
  validates :unit, presence: true, uniqueness: { case_sensitive: false, scope: :property_id }
  validates :floor, numericality: {greater_than_or_equal_to: 1}, if: Proc.new{|unit| unit.floor.present?}

  ### Class Methods

  def self.occupied
    # TODO: implement with Occupancy model
    self.all
  end

  ### Instance Methods
end
