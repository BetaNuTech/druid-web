module Users
  module Roles
    extend ActiveSupport::Concern

    included do
      belongs_to :role, required: false

      def administrator?
        role.try(:administrator?)
      end

      def corporate?
        role.try(:corporate?)
      end

      def agent?
        role.try(:agent?)
      end

      def admin?
        role.try(:admin?)
      end

      def manager?
        role.try(:manager?)
      end

      def user?
        role.try(:user?)
      end

    end
  end
end
