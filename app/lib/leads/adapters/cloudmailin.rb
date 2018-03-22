module Leads
  module Adapters
    class Cloudmailin
      # Input data is assumed to follow the CloudMailin multi-part post format
      #
      # See: http://docs.cloudmailin.com/http_post_formats/multipart/
      #

      LEAD_SOURCE_SLUG = 'Cloudmailin'


      def initialize(params)
        @property_code = get_property_code(params)
        @data = filter_params(params)
      end

      def parse
        return build(data: extract(@data), property_code: @property_code)
      end

      private

      def extract(data)
        CloudMailin::Parser.new(data).parse
      end

      def build(data:, property_code:)
        lead = Lead.new(data)
        lead.validate
        status = lead.valid? ? :ok : :invalid
        result = Leads::Creator::Result.new( status: status, lead: data, errors: lead.errors, property_code: property_code)
        return result
      end

      def get_property_code(params)
        to_addr = params.fetch(:envelope, {}).fetch(:to,'') || ""
        code = ( to_addr.split('@').first || "" ).split("+").last
        return code
      end

      def filter_params(params)
        return params
      end

      def sanitize(value)
        return ActionController::Base.helpers.sanitize(value)
      end
    end
  end

end
