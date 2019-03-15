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
#  read_at             :datetime
#  read_by_user_id     :uuid
#

class Message < ApplicationRecord
  ### Class Concerns/Extensions
  include Messages::StateMachine

  ### Constants
  ALLOWED_PARAMS = [:message_template_id, :subject, :body, :message_type_id]
  PREVIEW_LENGTH=200

  ### Associations
  belongs_to :user
  belongs_to :messageable, polymorphic: true, optional: true
  belongs_to :message_template, optional: true
  belongs_to :message_type
  belongs_to :read_by, foreign_key: 'read_by_user_id', class_name: 'User', optional: true
  has_many :deliveries, class_name: 'MessageDelivery', dependent: :destroy

  ### Validations
  validates :senderid, :recipientid, :subject, :body, presence: true

  ### Scopes
  scope :for_thread, ->(threadid) { where(threadid: threadid)}

  ### Callbacks
  before_validation :set_meta
  after_save :fail_on_delivery_failure

  ### Class Methods

  def self.unread
    where(read_at: nil).
      select{|r| r.incoming?}
  end

  # Mark collection as read by user
  def self.mark_read!(collection,user=nil)
    collection = Array(collection) if collection.is_a?(Message)
    collection.each do |record|
      record.read_at ||= DateTime.now
      ( record.read_by ||= user ) if user
      record.save!
    end
  end

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

  def self.format_phone(val)
    return nil if ( val.nil? || (!val.is_a?(String)) )
    return ( "+1" + val.gsub(/[^\d]/,'').sub(/\A1/,'') )
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

    message.load_template if !message.body.present? && !message.subject.present?

    return message
  end

  ### Instance Methods

  def read?
    return true if outgoing?
    return incoming? && !read_at.nil?
  end

  def body_missing?
    (body || '').empty?
  end

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
      if message_type && rich_editor?
        self.body = self.body.gsub(/[\n]+/, '<BR/>')
      end
    end
    return !any_errors
  end

  def load_template
    if !body.present? && message_template.present?
      self.subject = message_template.subject_with_data(template_data)
      self.body = message_template.body_with_data(template_data)
    end
  end

  def body_with_layout
    (message_template || MessageTemplate.new).apply_layout(body)
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
    delivery.delay(queue: :messages).perform
    delivery.reload
    self.delivered_at = delivery.delivered_at
    save!
  end

  def fail_on_delivery_failure
    reload
    return true if failed?
    if (last_delivery = deliveries.order(created_at: 'desc').first).present?
      unless last_delivery.success?
        self.fail!
      end
    end
    return true
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
    case
    when message_type.nil?
      return 'NONE'
    when message_type.sms?
      return Messages::Sender.find_adapter(self).base_senderid
    when message_type.email?
      return Messages::Sender.find_adapter(self).base_senderid.
              sub('@',"+#{threadid}@")
    end
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

  def html?
    message_type.present? ? message_type.html : true
  end

  def rich_editor?
    html? && !( body || '' ).match(/<html>/)
  end

end
