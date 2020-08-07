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
end
