module Messages
  module DeliveryAdapters
    class CloudMailin

      attr_reader :data

      class << self
        def response_for(message)
          if message.valid?
            return {
              status: :created,
              format: :json,
              body: message.to_json
            }
          else
            return {
              status: :unprocessable_entity,
              format: :json,
              body: {errors: message.errors}.to_json
            }
          end
        end
      end

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
        return result
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
