module Api
  module V1
    class ReferralBouncesController < ApiController
      DEFAULT_URL =  'https://www.bluestonemap.com/'.freeze

      # This method handles referral logic and redirects to the website URL.
      # It creates a referral bounce record and handles any errors that occur.
      def refer
        website_url = ReferralBounceService.new(request).create_bounce || DEFAULT_URL
        redirect_to website_url
      end

      private

      def referral_bounce_params
        @referral_bounce_params ||= params.permit(:api_token, :propertycode, :campaignid, :trackingid)
      end
    end
  end
end
