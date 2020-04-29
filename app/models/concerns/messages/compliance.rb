module Messages
  module Compliance
    extend ActiveSupport::Concern

    included do


      enum classification: {default: 0, internal: 1, system: 2, compliance: 3}
      scope :for_compliance, ->() { where(classification: 'compliance') }

      def for_compliance?
        classification == 'compliance'
      end

    end

  end
end
