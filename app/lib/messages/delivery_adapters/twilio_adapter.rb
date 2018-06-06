module Messages
  module DeliveryAdapters
    class TwilioAdapter
      require 'twilio-ruby'

      CLIENT = ::Twilio::REST::Client
      SID_ENV = 'MESSAGE_DELIVERY_TWILIO_SID'
      TOKEN_ENV = 'MESSAGE_DELIVERY_TWILIO_TOKEN'
      PHONE_ENV = 'MESSAGE_DELIVERY_TWILIO_PHONE'

      attr_reader :sid, :token, :phone_number

      class << self
        def get_sid
          return ENV.fetch(SID_ENV,'')
        end

        def get_token
          return ENV.fetch(TOKEN_ENV,'')
        end

        def get_phone
          return ENV.fetch(PHONE_ENV,'')
        end
      end


      def initialize(params=nil)
        @data = filter_params(params)
        @sid = self.class.get_sid
        @token = self.class.get_token
        @client = nil
        @phone_number = self.class.get_phone
      end

      def base_senderid
        return self.class.get_phone
      end

      def parse
        return build(data: extract(@data))
      end

      def deliver(from: nil, to:, subject: nil, body:)
        result = nil
        if Rails.env.test?
          Rails.logger.warn "!!! Refusing to deliver SMS messages in TEST"
          result = true
        else
          msg = "Messages::DeliveryAdapters::TwilioAdapter sending SMS message to #{to}: #{body}"
          Rails.logger.info msg

          result = client.api.account.messages.create(
            from: format_phone(@phone_number),
            to: format_phone(to),
            body: body
          )
        end
        return result
      end

      private

      def extract(data)
        return Twilioadapter::Parser.new(data).parse
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

      # Format phone with a US prefix
      # Does not support non-US formats
      def format_phone(val)
        Message.format_phone(val)
      end

      def client
        return @client ||= CLIENT.new(@sid, @token)
      end


    end
  end
end
