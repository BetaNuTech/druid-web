# == Schema Information
#
# Table name: marketing_expenses
#
#  id                  :uuid             not null, primary key
#  property_id         :uuid             not null
#  marketing_source_id :uuid             not null
#  invoice             :string
#  description         :text
#  fee_total           :decimal(, )      not null
#  fee_type            :integer          default("free"), not null
#  quantity            :integer          default(1), not null
#  start_date          :date             not null
#  end_date            :date
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class MarketingExpense < ApplicationRecord
  ### Constants
  ALLOWED_PARAMS = [:invoice, :description, :start_date, :end_date, :fee_total, :fee_type, :quantity]
  FREE_FEE = 'free'
  ONETIME_FEE = 'onetime'
  LEAD_FEE = 'lead'
  MONTHLY_FEE = 'month'
  QUARTERLY_FEE = 'quarter'
  YEARLY_FEE = 'year'

  ### Extensions/Concerns
  audited

  ### Enums
  enum fee_type: { FREE_FEE => 0, ONETIME_FEE => 1, LEAD_FEE => 2, MONTHLY_FEE => 3, QUARTERLY_FEE => 4, YEARLY_FEE => 5 }

  ### Associations
  belongs_to :property
  belongs_to :marketing_source

  ### Validations
  validates :fee_type, presence: true
  validates :fee_total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :start_date, presence: true
  validate :validate_end_date

  ### Scopes
  scope :this_month, -> { where(start_date: DateTime.now.beginning_of_month..DateTime.now) }

  ### Class Methods

  ### Instance Methods

  def fee_type_period

  end

  private

  def validate_end_date
    errors.add(:end_date, 'must be later than start date') if end_date.present? && start_date.present? && end_date <= start_date
  end
end
