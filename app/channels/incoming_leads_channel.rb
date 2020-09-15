class IncomingLeadsChannel < ApplicationCable::Channel
  def subscribed
    property_id = params[:property_id]
    reject and return unless ( current_user && property_id )

    if policy(property_id).subscribe_incoming_leads_channel? && current_user.setting_enabled?(:lead_web_notifications)
      stream_from "#{Lead.property_incoming_leads_stream_base}:#{property_id}"
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
