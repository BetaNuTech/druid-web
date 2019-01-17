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
  require 'premailer'

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
            apply_layout(content)
          else
            content
          end
        template = Liquid::Template.parse(template_content)
        rendered_part = template.render(data)
        output[part] = Premailer.new(rendered_part, with_html_string: true).to_inline_css
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

  def apply_layout(content)
    rendered = ERB.new(message_template_layout).result(binding)
    output = rendered
    if html?
      output = Premailer.new(rendered, with_html_string: true).to_inline_css
    end
    return output
  end

  def body_with_data(template_data)
    template = Liquid::Template.parse(body)
    template.render(template_data)
  end

  def subject_with_data(template_data)
    template = Liquid::Template.parse(subject)
    template.render(template_data)
  end

  def body_preview
    content = body
    Premailer.new(ERB.new(message_template_layout).result(binding), with_html_string: true).to_inline_css
  end

  def shared?
    return !user_id.present?
  end

  def html?
    message_type.present? ? message_type.try(:html) : false
  end

  def rich_editor?
    html?
  end

  private

  def message_template_layout_filename
    filename = "%s.%s.erb" % [(message_type&.name&.downcase || 'default'), (message_type&.html? ? 'html' : 'text')]
  end

  def message_template_layout
    default_layout = '<%= content %>'
    layout_full_filename = File.join(Rails.root, 'app', 'views', 'layouts', 'message_templates', message_template_layout_filename)
    begin
      template_content = File.read(layout_full_filename)
    rescue => e
      Rails.logger.error "Could not find MessageTemplate layout at #{layout_full_filename}"
      template_content = default_layout
    end
    return template_content
  end

end
