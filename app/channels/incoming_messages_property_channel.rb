class IncomingMessagesPropertyChannel < ApplicationCable::Channel
  def subscribed
    property_id = params[:property_id]
    reject and return unless ( current_user && property_id &&
      current_user.setting_enabled?(:view_all_messages) &&
      current_user.setting_enabled?(:message_web_notifications))

    if policy(property_id).subscribe_incoming_messages_channel?
      stream_from "#{Message.property_incoming_messages_stream_base}:#{property_id}"
    else
      reject and return
    end
  end

  private

  def policy(property_id)
    property = Property.find(property_id)
    return PropertyPolicy.new(current_user, property)
  end
end
