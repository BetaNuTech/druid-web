module Messages
  class Sender
    attr_reader :message

    def initialize(message)
      @message = message
    end

  end
end
