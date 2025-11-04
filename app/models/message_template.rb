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
#  shared          :boolean          default(TRUE)
#

class MessageTemplate < ApplicationRecord
  require 'erb'
  require 'premailer'

  ### Class Concerns/Extensions
  audited
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
  ALLOWED_PARAMS = [:id, :message_type_id, :user_id, :shared, :name, :subject, :body]

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
    MessageTemplatePolicy::Scope.new(user, MessageTemplate).resolve
  end

  def self.available_for_user_and_type(user, message_type=nil)
    skope = self.available_for_user(user)
    if message_type.present?
      skope = skope.where(message_type_id: message_type.id)
    end
    return skope
  end

  def self.default(message=nil)
    default_template = MessageTemplate.new(
      name: 'default'
    )
    message_type = message&.message_type || MessageType.new(
      active: true,
      html: true,
      name: 'default'
    )
    default_template.message_type = message_type
    return default_template
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
            # Process content through Liquid first
            liquid_template = Liquid::Template.parse(content)
            processed_content = liquid_template.render(data)
            # Then apply layout with the processed content
            apply_layout_with_liquid(processed_content, data)
          else
            content
          end
        # For subject, still process through Liquid
        if part == :subject
          template = Liquid::Template.parse(template_content)
          output[part] = template.render(data)
        else
          # For body, it's already been processed
          output[part] = template_content
        end
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

  def apply_layout_with_liquid(content, template_data)
    # First process the layout through Liquid to replace template variables
    layout_template = message_template_layout
    liquid_template = Liquid::Template.parse(layout_template)
    processed_layout = liquid_template.render(template_data)

    # Then apply the processed layout with ERB
    rendered = ERB.new(processed_layout).result(binding)
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

  def body_preview(property: nil)
    content = body

    # Use property-specific graphics if property is provided, otherwise use defaults
    default_template_data = {
      'html_email_header_image' => property&.email_header_image_url || "%s://%s/email_header_sapphire-620.png" % [
        ENV.fetch('APPLICATION_PROTOCOL', 'https'),
        ENV.fetch('APPLICATION_HOST', 'localhost:3000')
      ],
      'email_business_logo' => property&.email_footer_logo_url || "%s://%s/bluecrest_logo_small.png" % [
        ENV.fetch('APPLICATION_PROTOCOL', 'https'),
        ENV.fetch('APPLICATION_HOST', 'localhost:3000')
      ],
      'email_housing_logo' => "%s://%s/equal_housing_logo.png" % [
        ENV.fetch('APPLICATION_PROTOCOL', 'https'),
        ENV.fetch('APPLICATION_HOST', 'localhost:3000')
      ]
    }

    # Process the layout through Liquid first to replace template variables
    layout_template = message_template_layout
    liquid_template = Liquid::Template.parse(layout_template)
    processed_layout = liquid_template.render(default_template_data)

    # Then apply ERB with the content
    Premailer.new(ERB.new(processed_layout).result(binding), with_html_string: true).to_inline_css
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
