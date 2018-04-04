require_relative './adapters/druid'
require_relative './adapters/zillow'
require_relative './adapters/cloudmailin'

module Leads
  module Adapters
    # List valid/enabled adapter classes Here
    ### IMPORTANT: Values in the VALID array correspond directly to
    # the LeadSource record "slug"s
    SUPPORTED = [ 'Druid', 'Zillow', 'Cloudmailin', 'YardiVoyager' ]


    # Does the provided source match a valid Lead Adapter Source
    def self.supported_source?(source)
      SUPPORTED.include?(source)
    end
  end
end
