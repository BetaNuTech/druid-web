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
#  incoming            :boolean
#  since_last          :integer
#  classification      :integer          default("default")
#

class Message < ApplicationRecord
  ### Class Concerns/Extensions
  include Messages::StateMachine
  include Messages::Compliance
  include Messages::Broadcasts
  audited

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
  scope :read, ->() { where.not(read_at: nil)}
  scope :unread, ->() { where(read_at: nil)}
  #scope :display_order, ->() {
    #order(Arel.sql("CASE messages.state='draft' WHEN true THEN 0 ELSE 1 END,
          #CASE messages.read_at IS NULL WHEN true THEN 0 ELSE 1 END,
          #COALESCE(messages.delivered_at, messages.updated_at) DESC"))
  #}
  scope :display_order, ->() {
    order(Arel.sql("COALESCE(messages.delivered_at, messages.updated_at) DESC"))
  }
  scope :incoming, ->() { where(incoming: true) }
  scope :outgoing, ->() { where(incoming: false) }
  scope :sms, ->() { includes(:message_type).where(message_type: {name: MessageType::SMS_TYPE_NAME}) }
  scope :email, ->() { includes(:message_type).where(message_type: {name: MessageType::EMAIL_TYPE_NAME}) }
  ### Callbacks
  before_validation :set_meta, on: [ :create ]
  before_validation :load_template, on: [ :create ]
  after_save :log_activity
  after_save :update_messageable_last_comm
  after_touch :update_messageable_last_comm

  ### Delegates
  delegate :sms?, :email?, to: :message_type, allow_nil: true

  ### Class Methods

  def self.pending_retry(start_time: 1.day.ago, end_time: Time.current)
    includes(:deliveries).
      outgoing.failed.
      where(
        messages: { created_at: start_time..end_time },
        deliveries: {
          status: MessageDelivery::FAILED,
          attempt: [1,2],
          log: MessageDelivery::PROVIDER_ERRORS
        }
      )
  end

  def self.retry_deliveries(start_time: 1.day.ago, end_time: Time.current)
    self.pending_retry(start_time: start_time, end_time: end_time).each do |message|
      begin
        message.deliver!
      rescue => e
        # noop
      end
    end
  end

  # Mark collection as read by user
  def self.mark_read!(collection,user=nil)
    collection = Array(collection) if collection.is_a?(Message)
    collection.each do |record|
      record.read_at ||= DateTime.current
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
        else
          return nil
        end
      rescue
        raise ActiveRecord::RecordNotFound
      end
    else
      return nil
    end
  end

  def self.format_phone(val)
    return nil if ( val.nil? || (!val.is_a?(String)) || (val ||"").empty? )
    return ( "+1" + val.gsub(/[^\d]/,'').sub(/\A1/,'') )
  end


  def self.new_message(from:, to:, message_type:, message_template: nil, threadid: nil, subject: nil, body: nil, classification: 'default', reply: false, add_signature: true)
    message = Message.new(
      message_type: message_type,
      message_template: message_template,
      threadid: threadid,
      subject: subject,
      body: body,
      classification: classification
    )

    message.set_threadid

    if from.is_a?(User)
      message.user = from
      message.messageable = to
      message.senderid = message.outgoing_senderid
      message.recipientid = message.outgoing_recipientid
      message.incoming = false
    elsif to.is_a?(User)
      message.user = to
      message.messageable = from
      message.senderid = message.incoming_senderid
      message.recipientid = message.incoming_recipientid
      message.incoming = true
    end

    message.load_template(reply)
    message.load_signature if add_signature

    return message
  end

  def self.for_leads
    joins('INNER JOIN leads on leads.id = messages.messageable_id')
  end

  def self.relevant_to_leads
    where("leads.state != 'invalidated' AND messages.state != 'draft'")
  end

  ### Instance Methods

  def new_reply(user:)
    #new_body = rich_editor? ? " <br/><br/>----------<br/>" + body : body
    new_body = '' # No quote
    return Message.new_message(
      from: user,
      to: messageable,
      message_type: message_type,
      threadid: threadid,
      subject: subject || '',
      body: new_body,
      reply: true,
      add_signature: false
    )
  end

  def read?
    return !read_at.nil?
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

  def load_template(force=false)
    if ( force || !body.present? ) && message_template.present?
      self.subject = message_template.subject_with_data(template_data)
      self.body = message_template.body_with_data(template_data)
    end
  end

  def body_with_layout
    if incoming?
      <<~EOF
        <tt>#{body}</tt>
      EOF
    else
      (message_template || MessageTemplate.default(self)).apply_layout(body)
    end
  end

  def body_for_html_preview
    formatted_body = body
    tag_regex = /(<div>|<span>|<p>|<b>|<i>)/
    body_is_html = formatted_body.match(tag_regex).present?
    if !body_is_html
      formatted_body = ActionController::Base.helpers.word_wrap(
        formatted_body, line_width: 80)
      formatted_body = "<pre>" + formatted_body + "</pre>"
    end
    return ActionController::Base.helpers.sanitize(formatted_body)
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
    return false if deliveries.successful.exists?
    delivery = MessageDelivery.create!( message: self, message_type: message_type )
    delivery.perform
    delivery.reload
    reload

    if delivery.success?
      new_since_last = calculate_time_since_last_message
      if self.since_last != new_since_last # Only update if it changed or was nil
        update_column(:since_last, new_since_last)
      end

      create_sent_message_note_if_needed

    else
      self.fail! unless failed?
    end

    return delivery.success?
  end

  handle_asynchronously :perform_delivery, queue: :messages

  def from_address
    if message_type.email? && outgoing?
      # Use different email prefixes based on messageable type
      if messageable.is_a?(Lead) || messageable.is_a?(Roommate)
        email_prefix = 'leasing'
        display_suffix = ' Leasing'  # Add department to display name
      else
        email_prefix = 'bluesky'
        display_suffix = ''  # No suffix for non-leasing emails
      end

      verified_sender = "#{email_prefix}@#{ENV.fetch('SMTP_DOMAIN', 'mail.blue-sky.app')}"
      property_name = messageable.try(:property).try(:name) || 'Bluecrest Residential'

      return "\"#{property_name}#{display_suffix}\" <#{verified_sender}>"
    else
      return senderid
    end
  end

  def reply_to_address
    if message_type.email? && outgoing?
      # Use threaded CloudMailin address for replies
      return outgoing_senderid
    else
      return nil
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
      # For SMS: returns the Twilio phone number from MESSAGE_DELIVERY_TWILIO_PHONE
      return Messages::Sender.find_adapter(self).base_senderid
    when message_type.email?
      # For Email: CRITICAL - This must use the CloudMailin address from MESSAGE_DELIVERY_REPLY_TO
      # base_senderid returns the full CloudMailin address (e.g., "1b524cb3122f466ecc5a@cloudmailin.net")
      # We add the thread ID using '+' addressing: "1b524cb3122f466ecc5a+threadid@cloudmailin.net"
      # This allows CloudMailin to route replies back to the correct conversation thread
      # WARNING: Do NOT use SMTP_DOMAIN here - CloudMailin needs its specific address to route replies
      return Messages::Sender.find_adapter(self).base_senderid.sub('@',"+#{threadid}@")
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

  def handle_message_delivery(delivery)
    messageable&.handle_message_delivery(delivery)
    self.delay.broadcast_to_streams if incoming?
    return true
  end

  def set_missing_incoming_flag
    return true unless incoming.nil?
    detect_incoming_from_recipient || detect_outgoing_from_recipient
    save
  end

  def outgoing?
    !incoming?
  end

  def calculate_time_since_last_message
    return nil unless messageable.present? && self.delivered_at.present?

    prior_messages = messageable.messages.where.not(id: self.id).where('delivered_at < ?', self.delivered_at).order(delivered_at: :desc)
    last_message_in_thread = prior_messages.first

    if last_message_in_thread.present?
      if last_message_in_thread.incoming == self.incoming # Last message was from SAME sender as current message
        return nil # Not a direct reply to the other party, or continuation of own monologue
      else # Last message was from OTHER sender
        return self.delivered_at.to_i - last_message_in_thread.delivered_at.to_i
      end
    else
      # No prior messages in thread from anyone. This is the first message for this messageable.
      if !self.incoming && messageable.is_a?(Lead) && messageable.respond_to?(:first_comm) && messageable.first_comm.present?
        return self.delivered_at.to_i - messageable.first_comm.to_i
      else
        return nil
      end
    end
  end

  def load_signature
    if rich_editor? && user&.use_signature?
      self.body = ( self.body || '' ) + "<br/><br/>" + user.profile.signature
    end
  end

  def previous_messages_in_thread
    Message.where(threadid: self.threadid).where.not(id: self.id).order(created_at: :desc)
  end

  def related_messages
    messageable ? messageable.messages.order(created_at: :desc) : []
  end

  def allows_reply?
    incoming? && ( messageable.message_types_available.include?(message_type) rescue true )
  end

  def mark_as_read_by_sender
    if outgoing? && user.present?
      self.read_at ||= Time.current
      self.read_by_user_id = user.id
      self.save if persisted?
    end
    true # Return true to ensure callback chain continues
  end

  def log_activity
    return true unless messageable.present? && messageable.is_a?(Lead) && messageable.persisted?
    note_body = nil
    note_action = nil

    if state == 'received' && incoming? && saved_change_to_state?(from: 'draft', to: 'received')
      note_body = "RECEIVED: #{subject}"
      note_action = 'Incoming Message'
    end


    if note_body.present?
      lead_action = LeadAction.find_or_create_by(name: note_action)
      messageable.comments.create(
        user: user,
        lead_action: lead_action,
        content: note_body,
        notable: self
      )
    end
    return true
  end

  def update_messageable_last_comm
    return true unless messageable.present? && messageable.respond_to?(:last_comm=)

    if outgoing? && state == 'sent' && delivered_at.present? && (saved_change_to_delivered_at? || saved_change_to_state?(to: 'sent'))
      if messageable.last_comm.nil? || delivered_at > messageable.last_comm
        messageable.update_column(:last_comm, delivered_at)
      end
    end
    return true
  end

  # Helper method to check if since_last was already calculated and persisted for current delivered_at
  def persisted_since_last?
    self.since_last.present?
  end

  def handle_twilio_status_change(params)
    # Implementation of handle_twilio_status_change method
  end

  private

  def detect_incoming_from_recipient
    if recipientid.present? && outgoing_senderid.present?
      if recipientid == outgoing_senderid
        self.incoming = true
      end
      return true
    else
      return false
    end
  end

  def detect_outgoing_from_recipient
    if senderid.present? && outgoing_senderid.present?
      if senderid == outgoing_senderid
        self.incoming = false
      end
      return true
    else
      return false
    end
  end

  def create_sent_message_note_if_needed
    return true unless messageable.is_a?(Lead) && messageable.persisted?
    return true unless outgoing?

    note_action = 'Outgoing Message'
    lead_action = LeadAction.find_or_create_by(name: note_action)
    
    unless messageable.comments.exists?(notable: self, lead_action: lead_action)
      comment_content = if message_type&.sms?
        "Sent: [SMS]"
      elsif message_type&.email?
        "Sent: [Email] #{subject}"
      else
        "Sent: #{subject}"
      end
      
      messageable.comments.create(
        user: user,
        lead_action: lead_action,
        content: comment_content,
        notable: self
      )
    end
    true
  end

end
