module Properties
  module Users
    extend ActiveSupport::Concern

    included do
      has_many :property_users, dependent: :destroy
      has_many :users, through: :property_users

      accepts_nested_attributes_for :property_users,
        allow_destroy: true,
        reject_if: proc{|attributes| attributes['user_id'].blank?}

      def agents
        users.references(:property_users).
          where(property_users: {
            role: PropertyUser::AGENT_ROLE
          })
      end

      def managers
        users.references(:property_users).
          where(property_users: {
            role: PropertyUser::MANAGER_ROLE
        })
      end

      def users_available_for_assignment
        User.includes(assignments: {user: :profile}).
          where(property_users: {id: nil}).
          order('user_profiles.last_name ASC, user_profiles.first_name ASC')
      end

      def users_available_for_lead_assignment
        User.includes(assignments: {user: :profile}).
          where(property_users: {property_id: self.id}).
          order('user_profiles.last_name ASC, user_profiles.first_name ASC')
      end

      def primary_agent
        managers.first || agents.first
      end

      def assign_user(user:, role:)
        PropertyUser.create(user: user, property: self, role: role)
      end

    end
  end
end
