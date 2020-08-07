module MarketingSources
  class IncomingIntegrationHelper
    attr_reader :property, :integration

    LEAD_SOURCE_DEFAULT = '_Default'

    LEAD_SOURCES = {
      'Arrowtel' => {
        description: 'Leads are auto-generated from incoming calls',
        tracking_number: '',
        destination_number: ->(property) { property&.phone || '' },
        tracking_email: false,
        tracking_code: false
      },
      'Bluesky' => {
        description: 'NO INTEGRATION: Manually entered leads',
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      },
      'BlueskyPortal' => {
        description: 'Leads are generated from a web form linked elsewhere',
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: ''
      },
      'Cloudmailin' => {
        description: 'Integrations with ILS\'s which email Leads to Bluesky through a tracking email',
        tracking_number: false,
        destination_number: false,
        tracking_email: ->(property) {
          source = LeadSource.where(slug: 'Cloudmailin').first or raise 'Cloudmailin LeadSource not found!'
          cloudmailin_listing = PropertyListing.where(property_id: property.id, source_id: source.id).first
          outgoing_replyto = Messages::DeliveryAdapters::Actionmailer.new.base_senderid
          outgoing_replyto.sub('@',"+#{cloudmailin_listing.code}@")
        },
        tracking_code: false
      },
      'Costar' => {
        description: 'Direct CoStar -> Bluesky Integration',
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      },
      'ForRent' => {
        description: 'Direct ForRent -> Bluesky Integration',
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      },
      'RentPath' => {
        description: 'Direct RentPath -> Bluesky Integration',
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      },
      'Zillow' => {
        description: 'Direct Zillow -> Bluesky Integration',
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      },
      '_Default' => {
        description: 'ERROR',
        tracking_number: '',
        destination_number: '',
        tracking_email: '',
        tracking_code: ''
      }
    }

    def initialize(property:, integration: nil)
      @property = case property
                  when Property
                    property
                  when String
                    Property.find(property)
                  end
      @integration = case integration
                     when LeadSource
                       integration
                     when String
                       LeadSource.where('id = :id OR slug = :id', {id: integration})
                     else
                       LeadSource.default
                     end
    end

    def options_for_integration
      slug = @integration&.slug || LEAD_SOURCE_DEFAULT
      base_data = LEAD_SOURCES.fetch(slug, LEAD_SOURCES[LEAD_SOURCE_DEFAULT])
      options = {}
      base_data.each_pair do |key, value|
        options[key] = case value
                    when Proc
                      value.call(@property)
                    else
                      value
                    end
      end
      options
    end

    def new_marketing_source_attributes
      options = options_for_integration
      {
        property_id: @property.id,
        lead_source_id: @integration.id,
        tracking_code: options[:tracking_code] || nil,
        tracking_email: options[:tracking_email] || nil,
        tracking_number: options[:tracking_number] || nil,
        destination_number: options[:destination_number] || nil
      }
    end
  end
end
