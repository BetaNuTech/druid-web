module Messages
  module DeliveryAdapters
    class Cloudmailin

      def initialize(params)
        @data = filter_params(params)
      end

      def parse
        return build(data: extract(@data))
      end

      private

      def extract(data)
        return Cloudmailin::Parser.new(data).parse
      end

      def build(data:)
        message = Message.new(data)
        message.validate
        status = message.valid? ? :ok : :invalid
        result = Messages::Receiver::Result.new( status: status, message: data, errors: message.errors )
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
