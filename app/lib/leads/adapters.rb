module Leads
  module Adapters
    # List valid/enabled adapter classes Here
    VALID = [ 'Druid' ]

    # Does the provided source match a valid Lead Adapter Source
    def self.valid_source?(source)
      VALID.include?(source)
    end
  end
end
