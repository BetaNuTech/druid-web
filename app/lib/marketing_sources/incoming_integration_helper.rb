module MarketingSources
  class IncomingIntegrationHelper
    attr_reader :property, :integration

    LEAD_SOURCE_DEFAULT = '_Default'

    LEAD_SOURCES = {
      'Arrowtel' => {
        description: 'Leads are auto-generated from calls directly to the main number (Arrowtel phone systems only)',
        tracking_number_enabled: true,
        destination_number_enabled: true,
        tracking_email_enabled: false,
        tracking_code_enabled: false,
        tracking_number: '',
        destination_number: ->(property) { property&.phone || '' },
        tracking_email: false,
        tracking_code: false
      },
      'Bluesky' => {
        description: 'NO INTEGRATION: Manually entered leads',
        tracking_number_enabled: false,
        destination_number_enabled: false,
        tracking_email_enabled: false,
        tracking_code_enabled: false,
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      },
      'BlueskyPortal' => {
        description: 'Leads are generated from a web form linked elsewhere',
        destination_number_enabled: false,
        tracking_code_enabled: true,
        tracking_email_enabled: false,
        tracking_number_enabled: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: ''
      },
      'CallCenter' => {
        description: 'Leads are auto-generated from incoming calls to Blueconnect',
        tracking_number_enabled: true,
        destination_number_enabled: true,
        tracking_email_enabled: false,
        tracking_code_enabled: false,
        tracking_number: '',
        destination_number: ->(property) { property&.phone || '' },
        tracking_email: false,
        tracking_code: false
      },
      'Cloudmailin' => {
        description: 'Integrations with ILS\'s which email Leads to Bluesky through a tracking email',
        tracking_number_enabled: false,
        destination_number_enabled: false,
        tracking_email_enabled: true,
        tracking_code_enabled: false,
        tracking_number: false,
        destination_number: false,
        tracking_email: ->(property) {
          source = LeadSource.where(slug: 'Cloudmailin').first or raise 'Cloudmailin LeadSource not found!'
          cloudmailin_listing = PropertyListing.where(property_id: property.id, source_id: source.id).first
          outgoing_replyto = ENV.fetch('CLOUDMAILIN_LEAD_ADDRESS','')
          outgoing_replyto.sub('@',"+#{cloudmailin_listing.code}@")
        },
        tracking_code: false
      },
      'Costar' => {
        description: 'Direct CoStar -> Bluesky Integration',
        tracking_number_enabled: false,
        destination_number_enabled: false,
        tracking_email_enabled: false,
        tracking_code_enabled: false,
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      },
      'ForRent' => {
        description: 'Direct ForRent -> Bluesky Integration',
        tracking_number_enabled: false,
        destination_number_enabled: false,
        tracking_email_enabled: false,
        tracking_code_enabled: false,
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      },
      'RentPath' => {
        description: 'Direct RentPath -> Bluesky Integration',
        tracking_number_enabled: false,
        destination_number_enabled: false,
        tracking_email_enabled: false,
        tracking_code_enabled: false,
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      },
      'Zillow' => {
        description: 'Direct Zillow -> Bluesky Integration',
        tracking_number_enabled: false,
        destination_number_enabled: false,
        tracking_email_enabled: false,
        tracking_code_enabled: false,
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      },
      '_Default' => {
        description: '',
        tracking_number_enabled: false,
        destination_number_enabled: false,
        tracking_email_enabled: false,
        tracking_code_enabled: false,
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      },
      'Phone and Email' => {
        description: 'Leads are auto-generated from incoming calls and emails using tracking numbers and tracking emails',
        tracking_number_enabled: true,
        destination_number_enabled: true,
        tracking_email_enabled: true,
        tracking_code_enabled: false,
        tracking_number: false,
        destination_number: false,
        tracking_email: false,
        tracking_code: false
      }
    }

    def self.lead_source_selection_options
      [
        ['', nil],
        ['Bluesky', LeadSource.where(slug: 'Bluesky').pluck(:id).first],
        ['Bluesky Portal', LeadSource.where(slug: 'BlueskyPortal').pluck(:id).first],
        ['Phone and Email', 'Phone and Email']
      ]
    end

    def self.lead_email_source_selection_options
      [
        ['Cloudmailin', LeadSource.where(slug: 'Cloudmailin').pluck(:id).first]
      ]
    end

    def self.lead_phone_source_selection_options
      [
        ['Arrowtel', LeadSource.where(slug: 'Arrowtel').pluck(:id).first],
        ['CallCenter', LeadSource.where(slug: 'CallCenter').pluck(:id).first],
      ]
    end

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
                     when ''
                       nil
                     when nil
                      nil
                     when /-/
                       @integration = LeadSource.where(id: integration).last
                     when String
                       @integration = LeadSource.where(slug: integration).last
                     end

      @integration_slug = @integration ? @integration.slug : integration
    end

    def options_for_integration
      base_data = LEAD_SOURCES.fetch(@integration_slug, LEAD_SOURCES[LEAD_SOURCE_DEFAULT])
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
