module MessagesHelper

  def select_message_type_for(messageable)
    last_message_type = messageable.messages.order("delivered_at DESC").first.try(:message_type)
    available = ( [last_message_type] + messageable.message_types_available ).compact.uniq
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
    templates = MessageTemplate.available_for_user_and_type(current_user, message_type)
    options_for_select(templates.collect{|t| [t.name, t.id]}, value)
  end

  def any_message_templates_available?(message_type=nil)
    MessageTemplate.available_for_user_and_type(current_user, message_type).exists?
  end

  def edit_message_subject?(message=nil)
    return true if message.nil?
    return message.message_type.has_subject?
  end
end
