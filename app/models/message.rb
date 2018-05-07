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
#  message_type_id     :uuid
#  thread              :uuid
#

class Message < ApplicationRecord
  ### Class Concerns/Extensions
  include Messages::StateMachine

  ### Constants
  # TODO: Allowed params
  MESSAGE_DELIVERY_REPLY_TO_ENV='MESSAGE_DELIVERY_REPLY_TO'
  ALLOWED_PARAMS = [:message_template_id, ]

  ### Associations
  belongs_to :user
  belongs_to :messageable, polymorphic: true, optional: true
  belongs_to :message_template, optional: true
  belongs_to :message_type
  has_many :message_deliveries

  ### Validations
  validates :senderid, :recipientid, :subject, :body, presence: true

  ### Scopes
  scope :for_thread, ->(threadid) { where(thread: threadid)}

  ### Callbacks
  before_validation :set_meta

  ### Class Methods

  def self.base_senderid
    return ENV.fetch(MESSAGE_DELIVERY_REPLY_TO_ENV, 'default@example.com')
  end

  def self.new_message(from:, to:, message_type:, message_template: nil, thread: nil)
    message = Message.new(
      user: from,
      messageable: to,
      message_type: message_type,
      message_template: message_template,
      thread: thread
    )
    message.set_meta
    message.fill
    return message
  end

  ### Instance Methods

  def fill
    any_errors = false
    if message_template.present?
      rendered_template = message_template.render(template_data)
      if rendered_template.errors?
        any_errors = true
        rendered_template.errors.each do |err|
          errors.add(:message_template, err)
        end
      end
      self.subject = rendered_template.subject
      self.body = rendered_template.body
    end
    return !any_errors
  end

  def template_data
    return (messageable.present? && messageable.respond_to?(:message_template_data)) ? messageable.message_template_data : {}
  end


  def new_message_reply
    reject_attrs = [:id, :created_at, :updated_at, :delivered_at, :state, :message_template_id, :body ]
    attrs = attributes
    attrs.delete_if{|key,value| reject_attrs.include?(key.to_sym)}
    return Message.new(attrs)
  end

  def perform_delivery
    # TODO: create MessageDelivery object and send
  end

  def set_senderid
    set_thread
    self.senderid ||= Message.base_senderid.sub('@',"+#{thread}@")
  end

  def set_recipientid
    if messageable.present?
      newid = messageable.message_recipientid(message_type: message_type)
      self.recipientid = newid if newid.present?
    end
    return true
  end

  def set_thread
    self.thread ||= SecureRandom.uuid
  end

  def set_meta
    set_thread
    set_senderid
    set_recipientid
    return true
  end

end
