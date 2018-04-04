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
end
