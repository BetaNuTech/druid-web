module Leads
  module Messaging
    extend ActiveSupport::Concern

    included do
      has_many :messages, as: :messageable, dependent: :destroy

      def message_template_data
        {
          "lead_name" => name,
          'lead_floorplan' => ' ',
          "agent_name" => user.try(:name),
          "agent_title" => user.try(:title_for_property, property),
          "property_name" => property.try(:name),
          'property_city' => property.try(:city),
          'property_amenities' => ' ',
          'property_website' => property.try(:website),
          'property_phone' => property.try(:phone),
          'property_school_district' => property.try(:school_district)
        }
      end

      def message_recipientid(message_type:)
        if message_type.email?
          return message_email_destination
        end

        if message_type.sms?
          return message_sms_destination
        end
      end

      def message_sms_destination
        if respond_to?(:phone1_type) && respond_to?(:phone1) && phone1_type == 'Cell'
          return phone1
        elsif respond_to?(:phone2_type) && respond_to?(:phone2) && phone2_type == 'Cell'
          return phone2
        elsif respond_to?(:phone_type) && respond_to?(:phone) && phone_type == 'Cell'
          return phone
        elsif !respond_to?(:phone_type) && respond_to?(:phone)
          return phone
        else
          return nil
        end
      end

      def message_email_destination
        return try(:email)
      end

      def message_types_available
        types = []
        types << MessageType.active.sms if message_sms_destination.present?
        types << MessageType.active.email if message_email_destination.present?
        return types
      end
    end
  end
end