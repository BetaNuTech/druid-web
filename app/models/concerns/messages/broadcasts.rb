module Messages
  module Broadcasts
    extend ActiveSupport::Concern

    included do
      include ActionView::Helpers::SanitizeHelper

      def json_for_broadcast
        sanitized_body = strip_tags(body || '')
        sanitized_subject = strip_tags(subject || '')
        bc_preview = sanitized_body.truncate(27, separator: /\s/)
        bc_subject = sanitized_subject.truncate(27, separator: /\s/)

        alert_message = "%s %s: %s" % [
          ( sms? ? '📱' : '📩' ),
          (messageable_type == 'Lead' ? ( (messageable&.name || '')+' ' )  : '' ),
          (sms? ? bc_preview : bc_subject)
        ]

        return {
          id: id,
          alert_message: alert_message,
          messageable_id: messageable_id,
          messageable_type: messageable_type,
          subject: bc_subject,
          preview: bc_preview,
          user_id: user_id,
          delivered_at: delivered_at
        }
      end

      def broadcast_to_streams
        broadcast_stream_names.each do |stream_name|
          logger.debug("==> Broadcasting to #{stream_name}: #{json_for_broadcast}")
          ActionCable.server.broadcast(stream_name, json_for_broadcast)
        end
      end

      def broadcast_stream_names
        return [
          property_incoming_messages_stream_name,
          user_incoming_messages_stream_name
        ].compact
      end


      def property_incoming_messages_stream_name
        if messageable.respond_to?(:property_id)
          property_id = messageable.property_id
        else
          property_id = user&.property&.id
        end
        return property_id.present? ? "#{Message.property_incoming_messages_stream_base}:#{property_id}" : nil
      end

      def user_incoming_messages_stream_name
        return user_id.present? ? "#{Message.user_incoming_messages_stream_base}:#{user_id}" : nil
      end
    end

    class_methods do

      def property_incoming_messages_stream_base
        return "property_incoming_messages"
      end

      def user_incoming_messages_stream_base
        return "user_incoming_messages"
      end

    end
  end
end
