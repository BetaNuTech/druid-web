module Leads
  module Adapters
    module CloudMailin
      class OpenaiParser
        def self.match?(data)
          # This parser should be used as default when enabled
          # Check if OpenAI parsing is enabled via environment variable
          ENV.fetch('ENABLE_OPENAI_PARSER', 'false') == 'true'
        end
        
        def self.parse(data)
          # For async processing, we return minimal valid lead data
          # The actual parsing will happen in the background job
          {
            first_name: 'Processing',
            last_name: 'Via AI',
            email: extract_basic_email(data),
            phone1: nil,
            message: 'Lead is being processed by AI. Details will be updated shortly.',
            raw_data: data
          }
        end
        
        private
        
        def self.extract_basic_email(data)
          # Try to extract email from various sources as fallback
          from_header = data.dig(:headers, 'From') || data.dig(:envelope, :from) || ''
          
          # Extract email from headers like "John Doe <john@example.com>"
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
end