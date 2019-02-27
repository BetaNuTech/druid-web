module Properties
  module Logo
    extend ActiveSupport::Concern

    included do
      has_one_attached :logo

      attr_accessor :remove_logo

      after_save :purge_logo, if: :remove_logo

      def purge_logo
        logo.purge_later if logo.attached?
      end

    end
  end
end
