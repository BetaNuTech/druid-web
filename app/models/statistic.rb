# == Schema Information
#
# Table name: statistics
#
#  id                :uuid             not null, primary key
#  fact              :integer          not null
#  quantifiable_id   :uuid             not null
#  quantifiable_type :string           not null
#  resolution        :integer          default(1440), not null
#  value             :decimal(, )      not null
#  time_start        :datetime         not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Statistic < ApplicationRecord
  ### Class Concerns/Extensions
  include Statistics::LeadSpeed
  include Statistics::Tenacity

  ### Constants
  LEADSPEED_FACT = :leadspeed
  TENACITY_FACT = :tenacity

  ### Enums
  enum fact: { leadspeed: 0, tenacity: 1 }

  ### Associations
  belongs_to :quantifiable, polymorphic: true

  ### Validations
  validates :fact, presence: true
  validates :resolution, presence: true, numericality: { greater_than: 0 }
  validates :value, presence: true
  validates :time_start, presence: true

  ### Scopes
  scope :for_object, -> (obj) { where(quantifiable: obj) }
  scope :hourly, -> () { where(resolution: 1.hour.to_i / 60 )}
  scope :daily, -> () { where(resolution: 1.day.to_i / 60 )}
  scope :weekly, -> () { where(resolution: 1.week.to_i / 60 )}
  scope :monthly, -> () { where(resolution: 1.month.to_i / 60 )}
  scope :yearly, -> () { where(resolution: 1.year.to_i / 60 )}
  scope :leadspeed, ->() { where(fact: LEADSPEED_FACT) }
  scope :tenacity, ->() { where(fact: TENACITY_FACT) }
  scope :user, ->() { where(quantifiable_type: 'User') }
  scope :property, ->() { where(quantifiable_type: 'Property') }

  ### Class Methods

  def self.utc_hour_start
    Time.now.utc.beginning_of_hour
  end

  def self.utc_day_start
    Time.now.utc.beginning_of_day
  end

  def self.utc_month_start
    Time.now.utc.beginning_of_month
  end

  ### Instance Methods

  private

end
