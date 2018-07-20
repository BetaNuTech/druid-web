module Leads
  module Messaging
    extend ActiveSupport::Concern

    included do
      has_many :messages, as: :messageable, dependent: :destroy

      def message_template_data
        {
          "lead_name" => name,
          'lead_floorplan' => preference.try(:unit_type_name),
          "agent_name" => user.try(:name),
          "agent_title" => user.try(:title_for_property, property),
          "property_name" => property.try(:name),
          "property_address" => property.try(:address),
          "property_address_html" => property.try(:address_html),
          'property_city' => property.try(:city),
          'property_amenities' => property.try(:amenities),
          'property_website' => property.try(:website),
          'property_phone' => property.try(:phone),
          'property_school_district' => property.try(:school_district),
          'property_application_url' => property.try(:application_url),
          'html_email_header_image' => ("%s://%s/email_header_sapphire-620.png" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST','')]),
          'email_bluestone_logo' => ("%s://%s/bluestone_logo_small.png" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST','')]),
          'email_housing_logo' => ("%s://%s/equal_housing_logo.png" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST','')]),
          'email_unsubscribe_link' => ("%s://%s/unsubscribe" % [ENV.fetch('APPLICATION_PROTOCOL', 'https'), ENV.fetch('APPLICATION_HOST','')]),
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
        destination = nil
        if respond_to?(:phone1_type) && respond_to?(:phone1) && phone1_type == 'Cell'
          destination = phone1
        elsif respond_to?(:phone2_type) && respond_to?(:phone2) && phone2_type == 'Cell'
          destination = phone2
        elsif respond_to?(:phone_type) && respond_to?(:phone) && phone_type == 'Cell'
          destination = phone
        elsif !respond_to?(:phone_type) && respond_to?(:phone)
          destination = phone
        end
        destination = Message.format_phone(destination)
        return destination
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
