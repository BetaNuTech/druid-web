module Leads
  module Broadcasts
    extend ActiveSupport::Concern

    included do

      def json_for_broadcast
        {
          id: id,
          state: state,
          name: name,
          first_comm: first_comm,
          referral: referral,
          property: {
            id: property_id,
            name: property&.name
          }
        }
      end

      def broadcast_to_streams
        broadcast_stream_names.each do |stream_name|
          msg = "==> Broadcasting to #{stream_name}: #{json_for_broadcast}"
          logger.debug(msg)
          ActionCable.server.broadcast(stream_name, json_for_broadcast)
        end
      end

      def broadcast_stream_names
        return [
          property_incoming_leads_stream_name
        ].compact
      end


      def property_incoming_leads_stream_name
        return property.present? ? "#{Lead.property_incoming_leads_stream_base}:#{property.id}" : nil
      end
    end

    class_methods do

      def property_incoming_leads_stream_base
        return "property_incoming_leads"
      end

    end
  end
end
