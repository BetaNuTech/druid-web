module MessageTemplatesHelper
  def select_message_type(val)
    options_for_select(MessageType.active.order(:name).map{|t| [t.name, t.id]},val)
  end

  def select_message_template_user(val)
    options = [["Everyone", nil],["Personal",current_user.id]]
    options_for_select(options, val)
  end

  def select_message_template_user(message_template)
    options = ([ message_template&.user ] + policy(MessageTemplate).users_for_reassignment.to_a).
      compact.uniq.
      map{|u| [u.name, u.id]}
    options_for_select(options, message_template&.user_id)
  end
end
