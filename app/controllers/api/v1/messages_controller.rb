module Api
  module V1
    class MessagesController < ApiController
      before_action :validate_message_adapter_token

      def create
        #message_data = params
        message_data = get_post_data
        log_message_data(message_data)
        receiver = Messages::Receiver.new(data: message_data, token: api_token)
        @message = receiver.execute
        response_data = receiver.response
        render plain: response_data[:body],
               status: response_data[:status],
               format: response_data[:format]
      end


      private

      # Handle both Multi-Part and Raw post data
      def get_post_data
        params.permit!
        if ( request.raw_post.match(/Content-Disposition: form-data/) rescue true )
          return params
        else
          raw_data = CGI::parse(request.raw_post)
          data = {}
          raw_data.keys.each{|k| data[k] = raw_data[k][0]}
          return params.merge(data)
        end
      end

      def log_message_data(data)
        if ( ENV.fetch("DEBUG_MESSAGE_API", "false").downcase != 'false' )
          Rails.logger.warn "[#{DateTime.now} MESSAGE API] #{data.inspect}"
        end
      end

      def validate_message_adapter_token
        validate_source_token(source: MessageDeliveryAdapter, token: api_token)
      end
    end
  end
end
