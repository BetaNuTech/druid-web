module Users
  module Properties
    extend ActiveSupport::Concern

    included do
      has_many :property_users, dependent: :destroy
      has_many :assignments, class_name: 'PropertyUser'
      has_many :properties, through: :assignments

      # Default Property
      def property
        properties.first
      end

      def assigned_to_property?(property)
        case property
        when String
          return assignments.where(property_id: property).any?
        when Property
          return assigned_to_property?(property.id)
        else
          return false
        end
      end

      def property_role(property_scope=nil)
        assignments.where(property: ( property_scope || property )).
          first&.role
      end

      def property_agent?(property_for_role = nil)
        assignments.where(property: ( property_for_role || property )).
          first&.agent?
      end

      def property_manager?(property_for_role = nil)
        assignments.where(property: ( property_for_role || property )).
          first&.manager?
      end

      def managed_properties
        property_ids = assignments.management_assignments.map(&:property_id)
        return Property.where(id: property_ids)
      end

      def subordinates
        return User.includes(:assignments, :profile).
          where(property_users: {property: managed_properties})
      end

      def colleagues
        return User.includes(:assignments, :profile).
          where(property_users: {property: properties})
      end

      def assigned_properties_agents
        User.includes(:assignments).where(property_users: {property_id: properties.pluck(:id)})
      end

      def assigned_properties_agent_ids
        User.includes(:assignments).where(property_users: {property_id: properties.pluck(:id)}).pluck(:id)
      end

      # Override Devise hook for sending a reconfirmation after email address is changed
      def send_reconfirmation_instructions
        super
        send_email_reconfirmation_notification_to_manager
      end

      # Send notification of email change to managers or TRMs
      def send_email_reconfirmation_notification_to_manager
        return true unless self.unconfirmed_email.present?

        recipient = nil
        if property_agent?
          recipient = property.managers.map(&:email).join(',') rescue nil
        elsif property_manager?
          recipient = property.team.teamleads.map(&:email).join(',') rescue nil
        end
        
        # Return early if no recipient or empty recipient
        return true if recipient.blank?

        message = Message.new(
          message_type: MessageType.email,
          threadid: nil,
          subject: 'Security Alert: A Bluesky user changed their email address',
          body: "This is a system/security notification that #{self.name} changed their email address from #{self.email} to #{self.unconfirmed_email}. If this is unexpected, please confirm with the employee by phone or in person.",
          classification: 'system',
          user: self,
          messageable: self,
          incoming: false
        )
        message.senderid = message.outgoing_senderid
        message.recipientid = recipient
        message.save!
        message.deliver!

        return true
      end

    end
  end
end
