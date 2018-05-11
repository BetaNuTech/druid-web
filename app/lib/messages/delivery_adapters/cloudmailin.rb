module Messages
  module DeliveryAdapters
    class Cloudmailin

      def initialize(params)
        @threadid = get_threadid(params)
        @data = filter_params(params)
      end

      def parse
        return build(data: extract(@data), threadid: @threadid)
      end

      private

      def extract(data)
        return Cloudmailin::Parser.new(data).parse
      end

      def build(data:, threadid:)
        message = Message.new(data)
        message.validate
        status = message.valid? ? :ok : :invalid
        result = Messages::Receiver::Result.new( status: status, message: data, errors: message.errors, threadid: threadid)
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
