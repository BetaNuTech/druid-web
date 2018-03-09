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
  audited
  acts_as_schedulable :schedule

  ### Constants
  ALLOWED_PARAMS = [
    :id, :reason_id, :lead_action_id, :notable_id, :notable_type, :content,
    { schedule_attributes: Schedulable::ScheduleSupport.param_names }
  ]

  ### Validations
  #validates :notable_id, :notable_type,
    #presence: true

  ### Associations
  belongs_to :lead_action, required: false
  belongs_to :notable, polymorphic: true, required: false
  belongs_to :reason, required: false
  belongs_to :user, required: false

  ### Class Methods

  ### Instance Methods

end
