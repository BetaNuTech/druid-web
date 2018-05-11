module Messages
  module DeliveryAdapters
    module Cloudmailin
      class EmailParser

        def self.match?(data)
          return true
        end

        def self.parse(data)
          body = data.fetch(:plain,nil) || data.fetch(:html,nil) || ''
          from = data.fetch("envelope",{}).fetch("from")
          to = data.fetch("envelope",{}).fetch("to")
        end

      end
    end
  end
end
