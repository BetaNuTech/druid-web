# == Schema Information
#
# Table name: messages
#
#  id                  :uuid             not null, primary key
#  messageable_id      :uuid
#  messageable_type    :string
#  user_id             :uuid             not null
#  state               :string           default("draft"), not null
#  senderid            :string           not null
#  recipientid         :string           not null
#  message_template_id :uuid
#  subject             :string           not null
#  body                :text             not null
#  delivered_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Message < ApplicationRecord
  ### Class Concerns/Extensions
  include Messages::StateMachine

  ### Constants
  # TODO: Allowed params

  ### Associations
  belongs_to :user
  belongs_to :messageable, polymorphic: true, optional: true
  belongs_to :message_template, optional: true
  # has_many :message_deliveries

  ### Validations
  validates :senderid, :recipientid, :subject, :body, presence: true

  ## Scopes

  ### Class Methods

  ### Instance Methods

  def fill
    no_errors = true
    if message_template.present?
      template_data = messageable.respond_to?(:message_template_data) ? messageable.message_template_data : {}
      rendered_template = message_template.render(template_data)
      if rendered_template.errors?
        no_errors = false
        rendered_template.errors.each do |err|
          errors.add(:message_template, err)
        end
      end
      self.subject = rendered_template.subject
      self.body = rendered_template.body
    end
    return no_errors
  end

    def perform_delivery
    # TODO: create MessageDelivery object and send
  end

end
