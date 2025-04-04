# == Schema Information
#
# Table name: properties
#
#  id                   :uuid             not null, primary key
#  name                 :string
#  address1             :string
#  address2             :string
#  address3             :string
#  city                 :string
#  state                :string
#  zip                  :string
#  country              :string
#  organization         :string
#  contact_name         :string
#  phone                :string
#  fax                  :string
#  email                :string
#  units                :integer
#  notes                :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  active               :boolean          default(TRUE)
#  website              :string
#  school_district      :string
#  amenities            :text
#  application_url      :string
#  team_id              :uuid
#  call_lead_generation :boolean          default(TRUE)
#  maintenance_phone    :string
#  working_hours        :jsonb
#  timezone             :string           default("UTC"), not null
#  leasing_phone        :string
#  voice_menu_enabled   :boolean          default(FALSE)
#  appsettings          :jsonb
#

class Property < ApplicationRecord
  ### Class Concerns/Extensions
  include Properties::Appsettings
  include Properties::Team
  include Properties::Users
  include Properties::PhoneNumbers
  include Properties::MarketingSources
  include Properties::Logo
  include Properties::WorkingHours
  include Properties::Scheduling
  include Properties::YardiVoyager
  audited

  ### Constants

  ALLOWED_PARAMS = [ :name, :address1, :address2, :address3, :city, :state, :zip, :country,
                    :organization, :contact_name, :phone, :maintenance_phone, :leasing_phone,
                    :fax, :email, :website, :units, :notes, :school_district,
                    :amenities, :active, :application_url, :team_id, :timezone,
                    :logo, :remove_logo, :call_lead_generation, :voice_menu_enabled,
                    { working_hours: {} } ]

  ## Associations
  has_many :leads
  has_many :listings, class_name: 'PropertyListing', dependent: :destroy
  accepts_nested_attributes_for :listings, reject_if: proc{|attributes| attributes['code'].blank? && attributes['description'].blank? }
  has_many :unit_types, dependent: :destroy
  has_many :housing_units, class_name: 'Unit', dependent: :destroy
  has_many :residents, dependent: :destroy
  has_many :engagement_policies, dependent: :destroy
  has_many :comments, class_name: "Note", as: :notable, dependent: :destroy
  has_many :contact_events, through: :leads
  has_many :referral_bounces, dependent: :destroy

  ### Validations
  validates :name, presence: true, uniqueness: true
  validates :timezone, presence: true

  ### Scopes
  scope :active, -> { where(active: true) }
  scope :supporting_call_lead_generation, -> { where(call_lead_generation: true)}

  ### Callbacks

  ### Class Methods
  before_validation :format_phones

  # Lookup by ID or PropertyListing code
  def self.find_by_code_and_source(code:, source_id: nil)
    if source_id.nil?
      return Property.active.where(id: code).first
    else
      return PropertyListing.includes(:source).
        where( lead_sources: {id: source_id, active: true},
               property_listings: {code: code, active: true}).
        first.try(:property)
    end
  end

  def self.names_and_ids
    self.order(:name).pluck(:name, :id)
  end

  ## Instance Methods

  # Return array of all possible PropertyListings for this property.
  def present_and_possible_listings
    return ( listings + missing_listings ).sort_by{|l| l.source.try(:name) || ''}
  end

  # Return an array of PropertyListings which are not present for
  # this property
  def missing_listings
    LeadSource.where.not(id: [listings.map(&:source_id)]).map do |source|
      PropertyListing.new(property_id: self.id, source_id: source.id, active: false)
    end
  end

  def listing_code(source)
    return nil unless source.present?
    self.listings.where(source_id: source.id).first.try(:code)
  end

  def occupancy_rate
    (housing_units.occupied.count.to_f / [ housing_units.count || 1].min.to_f).round(1) * 100.0
  end

  def address(line_break="\n")
    [address1, address2, address3, "#{city} #{state} #{zip}"].
      compact.
      select{|c| (c || '').length > 0}.
      join(line_break)
  end

  def address_html
    address("<BR/>")
  end

  def duplicate_groups
    DuplicateLead.includes("lead").where(leads: {property_id: self.id}).groups
  end

  private

  def format_phones
    self.phone = PhoneNumber.format_phone(self.phone) if self.phone.present?
    self.maintenance_phone = PhoneNumber.format_phone(self.maintenance_phone) if self.maintenance_phone.present?
    self.leasing_phone = PhoneNumber.format_phone(self.leasing_phone) if self.leasing_phone.present?
    self.fax = PhoneNumber.format_phone(self.fax) if self.fax.present?
  end

end
