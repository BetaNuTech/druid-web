module Users
  module Roles
    extend ActiveSupport::Concern

    included do
      belongs_to :role, required: false

      ### System Roles
      def administrator?
        role.try(:administrator?) || false
      end

      def corporate?
        role.try(:corporate?) || false
      end

      def admin?
        administrator? || corporate?
      end

      def property?
        role.try(:property?) || false
      end

      def agent?
        property?
      end

      def manager?
        role.try(:manager?) || false
      end

      def user?
        role.try(:user?)
      end

    end
  end
end
