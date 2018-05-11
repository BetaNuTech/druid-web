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
      @errors = ActiveModel::Errors.new(Lead)
      @token = token
      @source = get_source(@token)
      @parser = get_parser(@source)
    end

    def execute

      # Validate Access Token for MessageDeliveryAdapter
      unless ( @source.present? && @token.present? )
        error_message =  "Invalid Access Token '#{@token}'}"
        @errors.add(:base, error_message)
        @message.errors.add(:base, error_message)
        return @message
      end

      # Validate Parser
      if @parser.nil?
        error_message = "Parser for MessageDeliveryAdapter not found: #{@source.try(:name) || 'UNKNOWN'}"
        @errors.add(:base, error_message)
        @message.errors.add(:base, error_message)
        return @message
      end

      parse_result = @parser.new(@data).parse

      # TODO
      @message = Message.new(parse_result.message)


    end

    private

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
