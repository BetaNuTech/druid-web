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
#  threadid            :string
#

class Message < ApplicationRecord
  ### Class Concerns/Extensions
  include Messages::StateMachine

  ### Constants
  MESSAGE_DELIVERY_REPLY_TO_ENV='MESSAGE_DELIVERY_REPLY_TO'
  ALLOWED_PARAMS = [:message_template_id, :subject, :body, :message_type_id]
  PREVIEW_LENGTH=200

  ### Associations
  belongs_to :user
  belongs_to :messageable, polymorphic: true, optional: true
  belongs_to :message_template, optional: true
  belongs_to :message_type
  has_many :deliveries, class_name: 'MessageDelivery'

  ### Validations
  validates :senderid, :recipientid, :subject, :body, presence: true

  ### Scopes
  scope :for_thread, ->(threadid) { where(threadid: threadid)}

  ### Callbacks
  before_validation :set_meta

  ### Class Methods

  def self.new_threadid
    SecureRandom.uuid.to_s.gsub('-','')
  end

  def self.identify_messageable_from_params(params)
    messageable_id = (params[:message] || {}).fetch(:messageable_id, params[:messageable_id])
    messageable_type = (params[:message] || {}).fetch(:messageable_type, params[:messageable_type])

    if params[:lead_id].present?
      return Lead.find(params[:lead_id])
    elsif messageable_id.present? && messageable_type.present?
      begin
      klass = Kernel.const_get(messageable_type)
      if klass.new.respond_to?(:messages)
        return klass.find(messageable_id)
      end
      rescue
        raise ActiveRecord::RecordNotFound
      end
    else
      return nil
    end
  end

  def self.base_senderid
    return ENV.fetch(MESSAGE_DELIVERY_REPLY_TO_ENV, 'default@example.com')
  end

  def self.new_message(from:, to:, message_type:, message_template: nil, threadid: nil, subject: nil, body: nil)
    message = Message.new(
      message_type: message_type,
      message_template: message_template,
      threadid: threadid,
      subject: subject,
      body: body
    )

    message.set_threadid

    if from.is_a?(User)
      message.user = from
      message.messageable = to
      message.senderid = message.outgoing_senderid
      message.recipientid = message.outgoing_recipientid
    elsif to.is_a?(User)
      message.user = to
      message.messageable = from
      message.senderid = message.incoming_senderid
      message.recipientid = message.incoming_recipientid
    end

    message.fill if !message.body.present? && !message.subject.present?

    return message
  end

  ### Instance Methods

  def fill
    any_errors = false
    if message_template.present?
      rendered_template = message_template.render(template_data)
      self.subject = ''
      self.body = ''
      if rendered_template.errors?
        any_errors = true
        rendered_template.errors.each do |err|
          errors.add_to_base(err)
        end
        self.subject += rendered_template.errors.subject.join('; ')
        self.body += rendered_template.errors.body.join('; ')
      end
      self.subject += rendered_template.subject || ''
      self.body += rendered_template.body || ''
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
    delivery = MessageDelivery.create!( message: self, message_type: message_type )
    delivery.perform
    self.delivered_at = delivery.delivered_at
    save
  end

  def from_address
    if message_type.email? && outgoing?
      return "\"#{user.name} at #{messageable.try(:property).try(:name) || 'Bluestone Properties'}\" <#{senderid}>"
    else
      return senderid
    end
  end

  def to_address
    return recipientid
  end

  def outgoing_senderid
    return Message.base_senderid.sub('@',"+#{threadid}@")
  end

  def outgoing_recipientid
    rid = nil
    if messageable.present?
      rid = messageable.message_recipientid(message_type: message_type)
    end
    return rid
  end

  def incoming_recipientid
    outgoing_senderid
  end

  def incoming_senderid
    outgoing_recipientid
  end

  def set_threadid
    self.threadid ||= self.class.new_threadid
  end


  def set_meta
    set_threadid
    return true
  end

  def incoming?
    return recipientid == outgoing_senderid
  end

  def outgoing?
    return senderid == outgoing_senderid
  end

  def sender_name
    return outgoing? ? user.name : messageable.name
  end

  def recipient_name
    return incoming? ? user.name : messageable.name
  end

end
