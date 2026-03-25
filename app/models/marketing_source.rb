# == Schema Information
#
# Table name: marketing_sources
#
#  id                   :uuid             not null, primary key
#  active               :boolean          default(TRUE)
#  property_id          :uuid             not null
#  lead_source_id       :uuid
#  name                 :string           not null
#  description          :text
#  tracking_code        :string
#  tracking_email       :string
#  tracking_number      :string
#  destination_number   :string
#  fee_type             :integer          default("free"), not null
#  fee_rate             :decimal(, )      default(0.0)
#  start_date           :date             not null
#  end_date             :date
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  phone_lead_source_id :uuid
#  email_lead_source_id :uuid
#


# MarketingSource model and logic
class MarketingSource < ApplicationRecord
  ### Class Concerns/Extensions
  include Seeds::Seedable
  include MarketingSources::Stats
  include MarketingSources::MarketingExpenses

  ### Constants
  ALLOWED_PARAMS = %w[active property_id name description tracking_email tracking_number tracking_code destination_number fee_type fee_rate start_date end_date lead_source_id phone_lead_source_id email_lead_source_id]
  # NOTE: the tracking_code attribute/column is unused as of 2021/01/28

  FREE_FEE = 'free'
  ONETIME_FEE = 'onetime'
  LEAD_FEE = 'lead'
  MONTHLY_FEE = 'month'
  QUARTERLY_FEE = 'quarter'
  YEARLY_FEE = 'year'
  LEASE_FEE = 'lease'

  ### Enums
  enum fee_type: { FREE_FEE => 0, ONETIME_FEE => 1, LEAD_FEE => 2, MONTHLY_FEE => 3, QUARTERLY_FEE => 4, YEARLY_FEE => 5, LEASE_FEE => 6 }

  ### Associations
  belongs_to :property
  belongs_to :lead_source, required: false
  belongs_to :phone_lead_source, required: false, class_name: 'LeadSource'
  belongs_to :email_lead_source, required: false, class_name: 'LeadSource'

  ### Validations
  validates :property_id, presence: true
  validates :name, presence: true, uniqueness: { scope: :property_id}
  validates :fee_type, presence: true
  validates :fee_rate, presence: true
  validates :start_date, presence: true
  validate :validate_end_date
  validates :tracking_number, uniqueness: true, unless: -> { tracking_number.blank? }

  ### Callbacks
  before_validation :format_phone_numbers
  before_save :strip_spaces_from_name
  before_save :clear_tracking_without_source

  ### Scopes
  scope :periodic, -> { where(fee_type: [MONTHLY_FEE, QUARTERLY_FEE, YEARLY_FEE]) }
  scope :active, -> { where(active: true) }
  scope :current, -> { active.where('marketing_sources.start_date <= :now AND marketing_sources.end_date > :now', { now: DateTime.current })}

  ### Class methods

  # Fee types for form select helper
  def self.fee_types_for_select
    MarketingSource.fee_types.to_a.map do |ms|
      [ms[0].capitalize, ms[0]]
    end
  end

  # SQL expression to normalize a name for flexible matching:
  # strips whitespace, lowercases, removes 'www.' prefix and '.com/.net/.org' suffix
  NORMALIZE_SQL = "LOWER(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(%s), '^www\\.', ''), '\\.(com|net|org)$', ''))".freeze

  # Attributable Leads using flexible matching (SQL-based)
  def self.all_leads(property=nil)
    skope = Lead
    skope = Lead.where(property: property) if property

    marketing_sources = property ? MarketingSource.where(property: property) : MarketingSource.all
    normalized_names = marketing_sources.pluck(:name).map { |n| normalize_name(n) }.uniq

    return skope.none if normalized_names.empty?

    skope.where(
      "#{NORMALIZE_SQL % 'referral'} IN (?)", normalized_names
    ).where.not(referral: [nil, ''])
  end

  # Attributable Lead Conversions
  def self.all_conversions(property=nil)
    all_leads(property).includes(:lead_transitions).
      where(lead_transitions: { last_state: 'prospect', current_state: 'showing'})
  end

  def self.format_phone(number,prefixed: false)
    # Strip non-digits
    out = ( number || '' ).to_s.gsub(/[^0-9]/,'')

    if out.length > 10
      # Remove US country code
      if (out[0] == '1')
        out = out[1..-1]
      end
    end

    # Truncate number to 10 digits
    out = out[0..9]

    # Add country code if we want to prefix
    if prefixed
      out = "1" + out
    end

    return out
  end

  def self.referral_fee(lead)
    self.current.where(property_id: lead.property_id, name: lead.referral).first&.fee_rate || 0.0
  end

  # Find marketing source by flexible name matching
  # Matches "Zillow" to "Zillow.com", "Apartments.com" to "Apartments", etc.
  def self.find_by_flexible_referral(property, referral_name)
    return nil if referral_name.blank?

    normalized_referral = normalize_name(referral_name)
    where(property: property)
      .where("#{NORMALIZE_SQL % 'name'} = ?", normalized_referral)
      .first
  end
  
  # Normalize name for flexible matching
  def self.normalize_name(name)
    return '' if name.blank?
    
    # Remove common TLD suffixes and www prefix, convert to lowercase
    normalized = name.to_s.strip.downcase
    normalized = normalized.gsub(/^www\./, '')      # Remove www. prefix
    normalized = normalized.gsub(/\.(com|net|org)$/i, '')  # Remove common TLDs (case insensitive)
    
    normalized
  end

  ### Public methods

  def leads
    normalized_name = self.class.normalize_name(name)
    property.leads
      .where("#{NORMALIZE_SQL % 'referral'} = ?", normalized_name)
      .where.not(referral: [nil, ''])
  end

  def conversions
    leads.includes(:lead_transitions).
      where(lead_transitions: { last_state: 'prospect', current_state: 'showing'})
  end

  private

  def strip_spaces_from_name
    self.name = self.name.strip if self.name.present?
    self.name
  end

  def validate_end_date
    errors.add(:end_date, 'Must be later than start date') if end_date.present? && start_date.present? && end_date <= start_date
  end

  def format_phone_numbers
    if self.tracking_number.present?
      if detected_prefix = self.tracking_number.match(/^\+(\d)/)
        self.tracking_number = self.class.format_phone(self.tracking_number, prefixed: false)
      else
        self.tracking_number = self.class.format_phone(self.tracking_number)
      end
    end
    if self.destination_number.present?
      if detected_prefix = self.tracking_number.match(/^\+(\d)/)
        self.destination_number = self.class.format_phone(self.destination_number, prefixed: false)
      else
        self.destination_number = self.class.format_phone(self.destination_number)
      end
    end
  end

  def clear_tracking_without_source
    if self.lead_source_id.nil?
      self.tracking_code = nil
    else
      self.email_lead_source_id = nil
      self.phone_lead_source_id = nil
    end
    if self.email_lead_source_id.nil?
      self.tracking_email = nil
    end
    if self.phone_lead_source_id.nil?
      self.tracking_number = nil
      self.destination_number = nil
    end
  end
end
