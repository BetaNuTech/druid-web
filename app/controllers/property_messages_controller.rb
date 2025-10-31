class PropertyMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property
  before_action :authorize_property_messages
  after_action :update_current_property_cookie, only: [:edit]
  # Preview actions are read-only, safe to skip CSRF for better reliability
  skip_before_action :verify_authenticity_token, only: [:preview_sms, :preview_email]

  def edit
    # Load a sample lead for preview purposes (always use clean sample data)
    @sample_lead = build_sample_lead

    # For showing current values in form
    @sms_opt_in_request = @property.sms_opt_in_request_message_with_default
    @sms_opt_in_confirmation = @property.sms_opt_in_confirmation_message_with_default
    @sms_opt_out_confirmation = @property.sms_opt_out_confirmation_message_with_default
    @welcome_email_subject = @property.lead_auto_welcome_email_subject_with_default
    @welcome_email_body = @property.lead_auto_welcome_email_body_with_default
  end

  def update
    if @property.update(property_message_params)
      flash[:success] = "Automatic messages have been updated successfully."
      redirect_to edit_property_messages_path(@property)
    else
      # Re-populate instance variables needed for the form (always use clean sample data)
      @sample_lead = build_sample_lead
      @sms_opt_in_request = @property.sms_opt_in_request_message || @property.sms_opt_in_request_message_with_default
      @sms_opt_in_confirmation = @property.sms_opt_in_confirmation_message || @property.sms_opt_in_confirmation_message_with_default
      @sms_opt_out_confirmation = @property.sms_opt_out_confirmation_message || @property.sms_opt_out_confirmation_message_with_default
      @welcome_email_subject = @property.lead_auto_welcome_email_subject || @property.lead_auto_welcome_email_subject_with_default
      @welcome_email_body = @property.lead_auto_welcome_email_body || @property.lead_auto_welcome_email_body_with_default

      flash.now[:error] = "Please fix the errors below before saving."
      render :edit
    end
  end

  def preview_sms
    message_type = params[:message_type]
    message_content = params[:message]

    # Get a sample lead for template variable replacement (always use clean sample data)
    sample_lead = build_sample_lead

    # Process template variables
    preview_text = process_template_variables(message_content, sample_lead)

    # Truncate to SMS length limit (160 characters)
    char_count = preview_text.length
    truncated = preview_text.length > 160

    render json: {
      preview: preview_text,
      char_count: char_count,
      truncated: truncated
    }
  end

  def preview_email
    # Get sample lead for template variables (always use clean sample data)
    @sample_lead = build_sample_lead

    # Get the subject and body from params or use current property values
    subject = params[:subject].presence || @property.lead_auto_welcome_email_subject_with_default
    body = params[:body].presence || @property.lead_auto_welcome_email_body_with_default

    # Process template variables
    @processed_subject = process_template_variables(subject, @sample_lead)
    @processed_body = process_template_variables(body, @sample_lead)

    # Add target="_blank" to all links in the preview so they open in new tabs
    @processed_body = add_target_blank_to_links(@processed_body)

    # Render preview in new window/tab
    render layout: false
  end

  private

  def set_property
    @property = @current_property = Property.find(params[:property_id])
  end

  def authorize_property_messages
    authorize @property, :edit_messages?
  end

  def update_current_property_cookie
    cookies[:current_property] = @property.id if @property
  end

  def property_message_params
    params.require(:property).permit(
      :sms_opt_in_request_message,
      :sms_opt_in_confirmation_message,
      :sms_opt_out_confirmation_message,
      :lead_auto_welcome_email_subject,
      :lead_auto_welcome_email_body
    )
  end

  def build_sample_lead
    # Build a sample lead with dummy data for preview purposes
    Lead.new(
      property: @property,
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.doe@example.com',
      phone1: '555-123-4567',
      phone1_type: 'Cell'
    )
  end

  def process_template_variables(content, lead)
    return '' if content.blank?

    # Get template data from lead
    template_data = lead.message_template_data

    # Use Liquid to process the template
    template = Liquid::Template.parse(content)
    template.render(template_data)
  rescue => e
    Rails.logger.error "Error processing template variables: #{e.message}"
    content # Return original content if processing fails
  end

  def add_target_blank_to_links(html_content)
    return html_content if html_content.blank?

    # Add target="_blank" to all <a> tags that don't already have a target attribute
    html_content.gsub(/<a\s+([^>]*?)href=/i) do |match|
      attributes = $1
      if attributes =~ /target\s*=/i
        # Already has target attribute, don't modify
        match
      else
        # Add target="_blank" and rel="noopener noreferrer" for security
        "<a #{attributes}target=\"_blank\" rel=\"noopener noreferrer\" href="
      end
    end
  end
end