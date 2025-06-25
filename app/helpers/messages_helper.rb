module MessagesHelper

  def select_message_type_for(messageable)
    last_message_type = messageable.messages.order("delivered_at DESC").first.try(:message_type)
    available = (messageable.message_types_available ).compact.uniq
    if available.size > 1
      return select_tag('message_type_id', options_for_select(available.collect{|t| [t.name, t.id]}))
    else
      return content_tag(:span) do
        hidden_field_tag('message_type_id', available.first.try(:id)) +
          content_tag(:span, available.first.try(:name))
      end
    end
  end

  def message_template_options(message_type=nil, value)
    templates = MessageTemplate.available_for_user_and_type(current_user, message_type).order("message_templates.name ASC")
    options_for_select(templates.collect{|t| [t.name, t.id]}, value)
  end

  def any_message_templates_available?(message_type=nil)
    MessageTemplate.available_for_user_and_type(current_user, message_type).exists?
  end

  def edit_message_subject?(message=nil)
    return true if message.nil?
    return message.message_type.has_subject?
  end

  def message_body_preview_content(message, line_width: 60, preview_length: 200)
    body_text = word_wrap(strip_tags(message.body || ''), line_width: line_width).gsub('&amp;', '&')
    truncate(body_text, length: preview_length, omission: "\n\n... (continued)")
  end

  def message_body_preview(message, line_width: 60)
    content_tag(:pre, class: 'message_body_preview') do
      message_body_preview_content(message, line_width: line_width)
    end
  end

  def message_delivery_indicator(message)
    if message.incoming?
      content_tag(:span, class: "message-direction-indicator incoming-indicator", title: "Incoming Message") do
        (content_tag(:span, "", class: "glyphicon glyphicon-arrow-down") + 
         content_tag(:span, "Incoming", class: "direction-label")).html_safe
      end
    elsif message.draft?
      content_tag(:span, class: "message-direction-indicator draft-indicator", title: "Draft Message") do
        (content_tag(:span, "", class: "glyphicon glyphicon-edit") + 
         content_tag(:span, "Draft", class: "direction-label")).html_safe
      end
    elsif message.failed?
      content_tag(:span, class: "message-direction-indicator failed-indicator", title: "Failed to Send: #{message.deliveries.last&.log || ''}") do
        (content_tag(:span, "", class: "glyphicon glyphicon-exclamation-sign") + 
         content_tag(:span, "Failed", class: "direction-label")).html_safe
      end
    else
      content_tag(:span, class: "message-direction-indicator outgoing-indicator", title: "Outgoing Message") do
        (content_tag(:span, "", class: "glyphicon glyphicon-arrow-up") + 
         content_tag(:span, "Outgoing", class: "direction-label")).html_safe
      end
    end
  end

  def message_delivery_indicator_link(message)
    if message.incoming?
      tooltip_block('message-type_indicator-incoming') do
        link_to(message_delivery_indicator(message), new_message_path(reply_to: message.id))
      end
    else
      tooltip_block('message-type_indicator-outgoing') do
        message_delivery_indicator(message)
      end
    end
  end

  def message_type_indicator(message)
    if message.sms?
      content_tag(:span, class: "message-type-indicator sms-indicator", title: "SMS Message") do
        (content_tag(:span, "", class: "glyphicon glyphicon-phone") + 
         content_tag(:span, "SMS", class: "message-type-label")).html_safe
      end
    elsif message.email?
      content_tag(:span, class: "message-type-indicator email-indicator", title: "Email Message") do
        (content_tag(:span, "", class: "glyphicon glyphicon-envelope") + 
         content_tag(:span, "Email", class: "message-type-label")).html_safe
      end
    else
      content_tag(:span, class: "message-type-indicator other-indicator", title: "Message") do
        (content_tag(:span, "", class: "glyphicon glyphicon-comment") + 
         content_tag(:span, "Message", class: "message-type-label")).html_safe
      end
    end
  end
end
