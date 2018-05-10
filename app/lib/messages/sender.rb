module Messages
  class Sender
    class Error < StandardError; end

    attr_reader :delivery, :adapter

    def initialize(delivery)
      @delivery = delivery
      validate!(delivery)
      @adapter = find_adapter!(delivery.message)
    end

    def deliver
      begin
        @adapter.deliver(
          from: delivery.message.senderid,
          to: delivery.message.recipientid,
          subject: delivery.message.subject,
          body: delivery.message.body
        )
        delivery.delivered_at = DateTime.now
        delivery.status = MessageDelivery::SUCCESS
        delivery.save!
      rescue => e
        delivery.status = MessageDelivery::FAILED
        delivery.log = e.to_s
        delivery.save!
      end
    end

    private

    def find_adapter!(message)
      available = MessageDeliveryAdapter.where(
        message_type_id: message.message_type_id,
        active: true
      ).order("created_at ASC")

      err_msg = "MessageDeliveryAdapter could not be found for #{message.message_type.name}"
      if available.any?
        adapter_record = available.first
        begin
          adapter = Kernel.const_get("Messages::DeliveryAdapters::#{adapter_record.name}")
          return adapter.new
        rescue
          Rails.logger.error err_msg
          raise Error.new(err_msg)
        end
      else
        Rails.logger.error err_msg
        raise Error.new(err_msg)
      end
    end

    def validate!(delivery)
      unless delivery.message.is_a?(Message) && delivery.message.present?
        msg = "Invalid MessageDelivery#{delivery.id}. Message not present"
        Rails.logger.error msg
        raise Error.new(msg)
      end

      unless delivery.message.valid?
        msg = "Invalid MessageDelivery#{delivery.id}. Message is invalid: #{delivery.message.errors.to_a}"
        Rails.logger.error msg
        raise Error.new(msg)
      end

      return true
    end


  end
end
