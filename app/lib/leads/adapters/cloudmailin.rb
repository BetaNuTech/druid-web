require_relative './cloud_mailin/cloud_mailin'

module Leads
  module Adapters
    class Cloudmailin
      # Input data is assumed to follow the CloudMailin multi-part post format
      #
      # See: http://docs.cloudmailin.com/http_post_formats/multipart/
      #

      LEAD_SOURCE_SLUG = 'Cloudmailin'

      def initialize(params)
        @property_code = get_property_code(params)
        @data = filter_params(params)
        @parser = nil
      end

      def parse
        # Store raw email for async processing if OpenAI parser is enabled
        if should_use_openai_parser?
          store_and_process_async
        elsif ( errors = reject?(@data) )
          Leads::Creator::Result.new(
            status: :nonlead,
            lead: {},
            errors: errors,
            property_code: @property_code,
            parser: @parser)
        else
          build(data: extract(@data), property_code: @property_code)
        end
      end

      def reject?(data)
        ( str = exception_list_match?(@data) ) ? ["Email exception list match: '#{str}'"] : false
      end

      private

      def extract(data)
        service = CloudMailin::Parser.new(data)
        @parser = service.parser
        service.parse
      end

      def build(data:, property_code:)
        lead = Lead.new(data)
        lead.validate
        status = lead.valid? ? :ok : :invalid
        result = Leads::Creator::Result.new( status: status, lead: data, errors: lead.errors, property_code: property_code, parser: @parser)
        return result
      end

      def get_property_code(params)
        params.permit! if params.respond_to?("permit!")
        to_addr = params.fetch(:envelope, {}).fetch(:to,'') || ""
        code = ( to_addr.split('@').first || "" ).split("+").last
        return code
      end

      def filter_params(params)
        return params
      end

      def sanitize(value)
        return ActionController::Base.helpers.sanitize(value)
      end

      def exception_list_match?(data)
        Leads::Adapters::CloudMailin::ContentExceptionList::REJECT.each do |str|
          email_data = data.to_s
          return str if email_data.match?(str)
        end
        false
      end
      
      def should_use_openai_parser?
        ENV.fetch('ENABLE_OPENAI_PARSER', 'false') == 'true'
      end
      
      def store_and_process_async
        # Store raw email
        raw_email = CloudmailinRawEmail.create_from_params(@data, @property_code)
        
        # Queue for async processing
        ProcessCloudmailinEmailJob.perform_later(raw_email)
        
        # Return a placeholder result for immediate response
        @parser = 'OpenAI (Async)'
        Leads::Creator::Result.new(
          status: :ok,
          lead: {
            first_name: 'Processing',
            last_name: 'Please Wait',
            email: extract_basic_email(@data),
            preference_attributes: {
              notes: 'This lead is being processed by AI. It will be updated shortly.'
            }
          },
          errors: ActiveModel::Errors.new(Lead.new),
          property_code: @property_code,
          parser: @parser
        )
      end
      
      def extract_basic_email(data)
        from_header = data.dig(:headers, 'From') || data.dig(:envelope, :from) || ''
        
        if match = from_header.match(/<(.+@.+)>/)
          match[1]
        elsif from_header.include?('@')
          from_header.strip
        else
          nil
        end
      end
    end
  end

end
