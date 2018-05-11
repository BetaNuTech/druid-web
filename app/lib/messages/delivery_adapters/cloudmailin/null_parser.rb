module Messages
  module DeliveryAdapters
    module Cloudmailin
      class NullParser

        def self.match?(data)
          true
        end

        def self.parse(data)
          return {
            recipientid: 'Null',
            senderid: 'Null',
            subject: 'Null',
            body: 'Null'
          }
        end
      end
    end
  end
end
