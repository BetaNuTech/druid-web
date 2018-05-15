module Api
  module V1
    class MessagesController < ApiController
      before_action :validate_message_adapter_token

      def create
        message_data = params
        receiver = Messages::Receiver.new(data: message_data, token: api_token)
        @message = receiver.execute
        if @message.valid?
          render :create, status: :created, format: :json
        else
          render json: {errors: receiver.errors}, status: :unprocessable_entity, format: :json
        end
      end


      private

      def validate_message_adapter_token
        validate_source_token(source: MessageDeliveryAdapter, token: api_token)
      end
    end
  end
end
