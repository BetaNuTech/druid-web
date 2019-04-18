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

    end
  end
end
