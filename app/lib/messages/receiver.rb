module Messages
  class Receiver
    class Error < StandardError; end

    class Result
      attr_reader :status, :message, :errors

      def initialize(status:, message:, errors:)
        @status = status
        @message = message
        @errors = errors
      end
    end

    attr_reader :data,
      :errors,
      :message,
      :parser,
      :saved,
      :source,
      :token

    def initialize(data:, token:)
      @message = Message.new
      @data = data
      @saved = false
      @errors = ActiveModel::Errors.new(Message)
      @token = token
      @source = get_source(@token)
      @parser = get_parser(@source)
    end

    def call

      # Validate Access Token for MessageDeliveryAdapter
      unless ( @source.present? && @token.present? )
        error_message =  "Invalid Access Token '#{@token}'}"
        add_error(error_message)
        return @message
      end

      # Validate Parser
      if @parser.nil?
        error_message = "Parser for MessageDeliveryAdapter not found: #{@source.try(:name) || 'UNKNOWN'}"
        add_error(error_message)
        return @message
      end

      parse_result = @parser.new(@data).parse

      @message = Message.new(parse_result.message)
      @message.incoming = true

      case parse_result.status
      when :ok
        @message.save && create_delivery_record(@message)
      else
        @message.validate
        parse_result.errors.each do |err|
          add_error(err)
        end
      end

      @errors = @message.errors

      return @message
    end

    def response
      @parser.response_for(@message)
    end

    private

    def add_error(error_message)
      err = error_message.to_s
      @errors.add(:base, err)
      @message.errors.add(:base, err)
    end

    def create_delivery_record(message)
      delivery = MessageDelivery.create(
        message: message,
        message_type: message.message_type,
        attempt: 1,
        attempted_at: message.delivered_at,
        status: MessageDelivery::SUCCESS,
        delivered_at: message.delivered_at
      )
      message.handle_message_delivery(delivery)
      
      # Add call to handle_message_response for lead preferences
      if message.messageable.is_a?(Lead) && message.messageable.preference.present?
        message.messageable.preference.handle_message_response(delivery)
      end
      
      return delivery
    end

    def create_failed_delivery_record(message)
      delivery = MessageDelivery.create(
        message: message,
        message_type: message.message_type,
        attempt: 1,
        attempted_at: message.delivered_at,
        status: MessageDelivery::FAILED,
        log: message.errors.to_a.join(';')
      )
      return delivery
    end

    def get_source(token)
      return MessageDeliveryAdapter.active.where(api_token: token).first
    end

    def get_parser(source)
      return nil unless source
      return Messages::DeliveryAdapters.supported_source?(source.slug) ?
        Object.const_get("Messages::DeliveryAdapters::#{source.slug}") :
        nil
    end
  end
end
