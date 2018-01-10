module Users
  module Roles
    extend ActiveSupport::Concern

    included do
      belongs_to :role, required: false

      def administrator?
        role.try(:administrator?)
      end

      def operator?
        role.try(:operator?)
      end

      def agent?
        role.try(:agent?)
      end

    end
  end
end
