# == Schema Information
#
# Table name: notes
#
#  id             :uuid             not null, primary key
#  user_id        :uuid
#  lead_action_id :uuid
#  reason_id      :uuid
#  notable_id     :uuid
#  notable_type   :string
#  content        :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Note < ApplicationRecord
  ### Class Concerns/Extensions
  acts_as_schedulable :schedule
  include Notes::Leads

  ### Constants
  ALLOWED_PARAMS = [
    :id, :reason_id, :lead_action_id, :notable_id, :notable_type, :content, :user_id,
    { schedule_attributes: Schedulable::ScheduleSupport.param_names }
  ]

  ### Validations
  #validates :notable_id, :notable_type,
    #presence: true

  ### Associations
  # belongs_to :schedule # via: acts_as_schedulable
  belongs_to :lead_action, required: false
  belongs_to :notable, polymorphic: true, required: false
  belongs_to :reason, required: false
  belongs_to :user, required: false

  ### Scopes
  scope :agent, -> { where.not(user_id: nil)}
  scope :timeline, -> { where(user_id: nil)}

  ### Class Methods

  def self.having_schedule
    self.joins("INNER JOIN schedules ON schedules.schedulable_type = 'Note' AND schedules.schedulable_id = notes.id")
  end

  def self.upcoming
    skope = self.having_schedule.
      where("schedules.date > ?", Date.today)
    return skope
  end

  def self.previous
    skope = self.having_schedule.
      where("schedules.date < ?", Date.today)
    return skope
  end

  def self.with_start_date(date)
    start_date = ( Date.parse(date).beginning_of_month rescue (Date.today.beginning_of_month) )
    self.having_schedule.
      where("schedules.date >= ?", start_date)
  end

  ### Instance Methods
  def start_time
    self.schedule.try(:date)
  end

  def notable_subject(user=nil)
    if notable.present?
      if notable === user
        "Personal Event/Note"
      else
        "%s (%s)" % [ notable.try(:name), notable_type ]
      end
    else
      'None'
    end
  end

end
