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
    if message.failed?
      delivery_status_class = 'btn-danger'
      title = 'Delivery Failure: ' + ( message.deliveries.last&.log || '' )
    else
      if message.draft?
        delivery_status_class = 'btn-default'
        title = 'Draft'
      else
        delivery_status_class = 'btn-success'
        title = 'Sent'
      end
    end
    container_class = 'btn btn-xs ' + delivery_status_class
    content_tag(:span, class: container_class, title: title) do
      message.incoming? ? glyph(:share_alt_left) : glyph(:send)
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
    container_class = "btn btn-xs btn-default"
    content_tag(:span, class: container_class) do
      case message
        when -> (m) { m.sms? }
          tooltip_block('message-type_indicator-phone') do
            glyph(:phone)
          end
        when -> (m) { m.email? }
          tooltip_block('message-type_indicator-email') do
            glyph(:envelope)
          end
        else
          tooltip_block('message-type_indicator-other') do
            glyph(:envelope)
          end
      end
    end
  end
end
