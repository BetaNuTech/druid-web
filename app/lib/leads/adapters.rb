require_relative './adapters/bluesky'
require_relative './adapters/bluesky_portal'
require_relative './adapters/zillow'
require_relative './adapters/cloudmailin'
require_relative './adapters/nextiva'

module Leads
  module Adapters
    # List valid/enabled adapter classes Here
    ### IMPORTANT: Values in the VALID array correspond directly to
    # the LeadSource record "slug"s
    SUPPORTED = [ 'Bluesky', 'Zillow', 'Cloudmailin', 'YardiVoyager', 'Costar', 'CallCenter', 'BlueskyPortal', 'Nextiva']


    # Does the provided source match a valid Lead Adapter Source
    def self.supported_source?(source)
      SUPPORTED.include?(source)
    end
  end
end
