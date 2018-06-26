module Messages
  class Sender
    class Error < StandardError; end

    attr_reader :delivery, :adapter

    def initialize(delivery)
      @delivery = delivery
      validate!(delivery)
      @adapter = find_adapter!(delivery.message)
    end

    def self.find_adapter(message)
      available = MessageDeliveryAdapter.where(
        message_type_id: message.message_type_id,
        active: true
      ).order("created_at ASC")

      err_msg = "MessageDeliveryAdapter could not be found for #{message.message_type.name}"
      if available.any?
        adapter_record = available.first
        adapter_name = adapter_record.slug
        begin
          raise "Invalid DeliveryAdapter #{adapter_name}" unless Messages::DeliveryAdapters.supported_source?(adapter_name)
          adapter_class_name = "::Messages::DeliveryAdapters::#{adapter_name}"
          adapter = Kernel.const_get(adapter_class_name)
          return adapter.new
        rescue => e
          err_msg = "#{err_msg}: #{e.to_s}"
          Rails.logger.error err_msg
          ErrorNotification.send(StandardError.new(err_msg))
          raise Error.new(err_msg)
        end
      else
        Rails.logger.error err_msg
        ErrorNotification.send(StandardError.new(err_msg))
        raise Error.new(err_msg)
      end
    end

    def deliver
      begin
        @adapter.deliver(
          from: delivery.message.from_address,
          to: delivery.message.to_address,
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
        delivery.message.reload
        delivery.message.fail!
      end
    end

    private

    def find_adapter!(message)
      self.class.find_adapter(message)
    end

    def validate!(delivery)
      unless delivery.message.is_a?(Message) && delivery.message.present?
        msg = "Invalid MessageDelivery#{delivery.id}. Message not present"
        Rails.logger.error msg
        ErrorNotification.send(StandardError.new(msg))
        raise Error.new(msg)
      end

      unless delivery.message.valid?
        msg = "Invalid MessageDelivery#{delivery.id}. Message is invalid: #{delivery.message.errors.to_a}"
        Rails.logger.error msg
        ErrorNotification.send(StandardError.new(msg))
        raise Error.new(msg)
      end

      return true
    end


  end
end
