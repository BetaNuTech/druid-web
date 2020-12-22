# == Schema Information
#
# Table name: marketing_sources
#
#  id                 :uuid             not null, primary key
#  active             :boolean          default(TRUE)
#  property_id        :uuid             not null
#  lead_source_id     :uuid
#  name               :string           not null
#  description        :text
#  tracking_code      :string
#  tracking_email     :string
#  tracking_number    :string
#  destination_number :string
#  fee_type           :integer          default("free"), not null
#  fee_rate           :decimal(, )      default(0.0)
#  start_date         :date             not null
#  end_date           :date
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class MarketingSource < ApplicationRecord
  ### Class Concerns/Extensions
  include Seeds::Seedable
  include MarketingSources::Stats
  include MarketingSources::MarketingExpenses

  ### Constants
  ALLOWED_PARAMS = %w[active property_id name description tracking_email tracking_number destination_number fee_type fee_rate start_date end_date lead_source_id]
  FREE_FEE = 'free'
  ONETIME_FEE = 'onetime'
  LEAD_FEE = 'lead'
  MONTHLY_FEE = 'month'
  QUARTERLY_FEE = 'quarter'
  YEARLY_FEE = 'year'

  ### Enums
  enum fee_type: { FREE_FEE => 0, ONETIME_FEE => 1, LEAD_FEE => 2, MONTHLY_FEE => 3, QUARTERLY_FEE => 4, YEARLY_FEE => 5 }

  ### Associations
  belongs_to :property
  belongs_to :lead_source, required: false

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

  ### Scopes
  scope :periodic, -> { where(fee_type: [MONTHLY_FEE, QUARTERLY_FEE, YEARLY_FEE]) }

  ### Class methods

  # Fee types for form select helper
  def self.fee_types_for_select
    MarketingSource.fee_types.to_a.map do |ms|
      [ms[0].capitalize, ms[0]]
    end
  end

  # Attributable Leads
  def self.all_leads(property=nil)
    skope = Lead
    skope = Lead.where(property: property) if property
    skope.where(referral: MarketingSource.all.pluck(:name) )
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

  ### Public methods

  def leads
    property.leads.where(referral: name)
  end

  def conversions
    leads.includes(:lead_transitions).
      where(lead_transitions: { last_state: 'prospect', current_state: 'showing'})
  end

  private

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
end
