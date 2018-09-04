module Users
  module Roles
    extend ActiveSupport::Concern

    included do
      belongs_to :role, required: false
      belongs_to :teamrole, required: false

      ### System Roles
      def administrator?
        role.try(:administrator?) || false
      end

      def corporate?
        role.try(:corporate?) || false
      end

      def agent?
        role.try(:agent?) || false
      end

      def admin?
        role.try(:admin?) || false
      end

      def manager?
        role.try(:manager?) || false
      end

      def user?
        role.try(:user?)
      end

      ### Team Roles

      def team_corporate?
        teamrole.try(:corporate?) || false
      end

      def team_manager?
        teamrole.try(:manager?) || false
      end

      def team_agent?
        teamrole.try(:agent?) || false
      end

    end
  end
end
