class IncomingMessagesUserChannel < ApplicationCable::Channel
  def subscribed
    reject and return unless current_user && current_user.setting_enabled?(:message_web_notifications)
    stream_from "#{Message.user_incoming_messages_stream_base}:#{current_user.id}"
  end

end
