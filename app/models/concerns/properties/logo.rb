module Properties
  module Logo
    extend ActiveSupport::Concern

    included do
      has_one_attached :logo
      has_one_attached :email_header_image
      has_one_attached :email_footer_logo

      attr_accessor :remove_logo

      # Only purge logo if explicitly requested with "1" value
      # Email graphics (header/footer) are never purged to preserve sent email integrity
      after_save :purge_logo, if: -> { remove_logo == "1" || remove_logo == true }

      def purge_logo
        logo.purge_later if logo.attached?
      end

      # Helper to get email header URL with fallback
      def email_header_image_url
        if email_header_image.attached?
          Rails.application.routes.url_helpers.rails_blob_url(
            email_header_image,
            only_path: false,
            protocol: ENV.fetch('APPLICATION_PROTOCOL', 'https'),
            host: ENV.fetch('APPLICATION_HOST', 'localhost:3000')
          )
        else
          # Fallback to default
          "%s://%s/email_header_sapphire-620.png" % [
            ENV.fetch('APPLICATION_PROTOCOL', 'https'),
            ENV.fetch('APPLICATION_HOST', 'localhost:3000')
          ]
        end
      end

      # Helper to get email footer URL with fallback
      def email_footer_logo_url
        if email_footer_logo.attached?
          Rails.application.routes.url_helpers.rails_blob_url(
            email_footer_logo,
            only_path: false,
            protocol: ENV.fetch('APPLICATION_PROTOCOL', 'https'),
            host: ENV.fetch('APPLICATION_HOST', 'localhost:3000')
          )
        else
          # Fallback to default
          "%s://%s/bluecrest_logo_small.png" % [
            ENV.fetch('APPLICATION_PROTOCOL', 'https'),
            ENV.fetch('APPLICATION_HOST', 'localhost:3000')
          ]
        end
      end

    end
  end
end
