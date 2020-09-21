module UserProfiles
  module Photo
    extend ActiveSupport::Concern

    included do
      has_one_attached :photo

      attr_accessor :remove_photo

      after_save :purge_photo, if: :remove_photo

      def purge_photo
        photo.purge_later if photo.attached?
      end

      # HACK: https://github.com/rails/rails/issues/37701
      def changed_for_autosave?
        super || remove_photo == '1'
      end

    end
  end
end
