# == Schema Information
#
# Table name: schedules
#
#  id               :uuid             not null, primary key
#  schedulable_type :string
#  schedulable_id   :uuid
#  date             :date
#  time             :time
#  rule             :string
#  interval         :string
#  day              :text
#  day_of_week      :text
#  until            :datetime
#  count            :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  duration         :integer
#  end_time         :time
#

class Schedule < Schedulable::Model::Schedule
  audited
  CUSTOM_PARAMS = [:duration, :end_time]
  ALLOWED_PARAMS = Schedulable::ScheduleSupport.param_names + CUSTOM_PARAMS

  before_save :set_end_time

  def to_datetime
    Time.zone.local(date.year, date.month, date.day, time.hour, time.min)
  end

  def end_time_to_datetime
    to_datetime + ( duration || 0 ).minutes
  end

  def short_date
    to_datetime.strftime('%m-%d')
  end

  def short_time
    to_datetime.strftime('%l:%M%p')
  end

  def short_datetime
    to_datetime.strftime('%m-%d %l:%M%p')
  end

  def long_datetime
    to_datetime.strftime('%B %e, %Y at %l:%M%p')
  end

  def long_date
    to_datetime.strftime('%B %e, %Y')
  end

  def conflict?(time)
    t = to_datetime
    time >= t && t < ( t + (duration ||0) )
  end

  private

  def set_end_time
    self.end_time = self.time + (duration || 0).minutes
  end
end
