# == Schema Information
#
# Table name: message_templates
#
#  id              :uuid             not null, primary key
#  message_type_id :uuid             not null
#  user_id         :uuid
#  name            :string           not null
#  subject         :string           not null
#  body            :text             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class MessageTemplate < ApplicationRecord
  require 'erb'

  ### Class Concerns/Extensions
  include Seeds::Seedable

  class Rendered
    attr_reader :subject, :body, :layout, :errors

    def initialize(subject: '', body: '', layout: '', errors: {})
      @subject = subject
      @body = body
      @layout = layout
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
  ALLOWED_PARAMS = [:id, :message_type_id, :user_id, :name, :subject, :body]

  ### Associations
  belongs_to :user, optional: true
  belongs_to :message_type

  ### Validations
  validates :name, :subject, :body, presence: true

  ## Scopes
  scope :sms, -> { where(message_type: MessageType.sms) }
  scope :email, -> { where(message_type: MessageType.email) }

  ### Class Methods

  def self.available_for_user(user)
    where(user_id: [nil, user.id])
  end

  def self.available_for_user_and_type(user, message_type=nil)
    skope = self.available_for_user(user)
    if message_type.present?
      skope = skope.where(message_type_id: message_type.id)
    end
    return skope
  end

  ### Instance Methods

  def render(data={})
    output = {subject: nil, body: nil, layout: nil, errors: {subject: [], body: []}}
    parts = {subject: subject, body: body}

    parts.each_pair do |part, content|
      template = nil
      begin
        template_content = case part
          when :body
            output[:layout] = message_template_layout_filename
            ERB.new(message_template_layout).result(binding)
          else
            content
          end
        template = Liquid::Template.parse(template_content)
        output[part] = template.render(data)
      rescue => e
        if template.nil?
          msg = "MessageTemplate Rendering Error (#{part}): #{e}"
          output[:errors][part] = [ msg ]
          Rails.logger.error msg
          ErrorNotification.send(StandardError.new(msg), {message_template: self.id})
        else
          if template.errors.any?
            msg = "MessageTemplate Rendering Error (#{part}): #{template.errors.join('; ')}"
            output[:errors][part] = template.errors
            Rails.logger.error msg
            ErrorNotification.send(StandardError.new(msg), {message_template: self.id})
          end
        end
      end
    end

    result = Rendered.new( subject: output[:subject],
                          body: output[:body],
                          layout: output[:layout],
                          errors: output[:errors])
    return result
  end

  def shared?
    return !user_id.present?
  end

  private

  def message_template_layout_filename
    filename = "%s.%s.erb" % [(message_type&.name&.downcase || 'default'), (message_type&.html? ? 'html' : 'text')]
  end

  def message_template_layout
    default_layout = '<%= content %>'
    layout_full_filename = File.join(Rails.root, 'app', 'views', 'layouts', 'message_templates', message_template_layout_filename)
    template_content =  File.read(layout_full_filename)# rescue default_layout
    return template_content
  end

end
