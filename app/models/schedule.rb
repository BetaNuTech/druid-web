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
#

class Schedule < Schedulable::Model::Schedule
  def to_datetime
    DateTime.new(date.year, date.month, date.day, time.hour, time.min)
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
end
