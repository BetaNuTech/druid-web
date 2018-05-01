class MessageTemplate < ApplicationRecord
  ### Class Concerns/Extensions
  include Seeds::Seedable

  class Rendered
    attr_reader :subject, :body, :errors

    def initialize(subject: '', body: '', errors: {})
      @subject = subject
      @body = body
      @errors = OpenStruct.new(
        subject: errors.fetch(:subject, []),
        body: errors.fetch(:body, []))
    end

    def errors?
      @errors.subject.present? || @errors.body.present?
    end

    def body?
      @body.present?
    end

    def subject?
      @subject.present?
    end
  end

  ### Constants

  ### Associations
  belongs_to :user, optional: true
  belongs_to :message_type

  ### Validations
  validates :name, :subject, :body, presence: true

  ## Scopes
  scope :sms, -> { where(message_type: MessageType.sms) }
  scope :email, -> { where(message_type: MessageType.email) }

  ### Class Methods

  ### Instance Methods

  def render(data={})
    output = {subject: '', body: '', errors: {subject: [], body: []}}
    parts = {subject: subject, body: body}

    parts.each_pair do |part, content|
      template = nil
      begin
        template = Liquid::Template.parse(content)
        output[part] = template.render(data)
      rescue => e
        if template.nil?
          msg = "MessageTemplate Rendering Error (#{part}): #{e}"
          output[:errors][part] = [ msg ]
          Rails.logger.error msg
        else
          if template.errors.any?
            msg = "MessageTemplate Rendering Error (#{part}): #{template.errors.join('; ')}"
            output[:errors][part] = template.errors
            Rails.logger.error msg
          end
        end
      end
    end

    result = Rendered.new(subject: output[:subject], body: output[:body], errors: output[:errors])
    return result
  end

end
