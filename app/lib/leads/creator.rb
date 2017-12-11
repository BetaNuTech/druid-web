module Leads
  class Creator
    attr_reader :data,
      :errors,
      :lead,
      :parser,
      :saved,
      :source,
      :token

    def initialize(data:, source: nil, agent: nil, validate_token: )
      @lead = Lead.new
      @saved = false
      @errors = ActiveModel::Errors.new(Lead)
      @data = data
      @token = token
      @source_slug = source
      @source = get_source(@source_slug)
      @parser = get_parser(@source)
      @token = verify_token(@source, validate_token)
    end

    # Create lead from provided data using detected Source adapter
    def execute

      # Validate Parser
      if @parser.nil?
        error_message =  "Parser for Lead Source not found: #{@source_slug}"
        @errors.add(:base, error_message)
        @lead.errors.add(:base, error_message)
        return @lead
      end

      # Validate Access Token for Lead Source
      case @token.first
      when :ok
        # NOOP : everything OK
      when :err
        error_message =  "Invalid Access Token for Lead Source: #{@source_slug}"
        @errors.add(:base, error_message)
        @lead.errors.add(:base, error_message)
        return @lead
      end

      parse_result = @parser.new(@data).parse
      lead_attributes = parse_result[:lead]

      @lead = Lead.new(lead_attributes)
      @lead.build_preference unless @lead.preference.present?
      @lead.source = @source

      case parse_result[:status]
        when :ok
          @lead.save
        else
          @lead.validate
          parse_result[:errors].each do |err|
            @lead.errors.add(:base, err)
          end
      end

      @errors = @lead.errors

      return @lead
    end

    private

    # Validate the source token
    #
    # Returns: [(:ok|:err), ("token value"|"error message")]
    def verify_token(source, token)
      return (token.present? && source.present? && source.api_token == token) ?
        [:ok, token] : [:err, 'Invalid Token']
    end

    # Lookup Source by slug or default
    def get_source(source_slug)
      return source_slug ?
        lookup_source(source_slug) :
        default_source
    end

    # Lookup LeadSource from provided slug
    def lookup_source(source_slug)
      LeadSource.active.where(slug: source_slug).first
    end

    # The default source is 'Druid'
    def default_source
      LeadSource.default
    end

    # Get Parser Class named like the Source slug
    def get_parser(source)
      return nil unless source
      return Leads::Adapters.supported_source?(source.slug) ?
        Object.const_get("Leads::Adapters::#{source.slug}") :
        nil
    end
  end
end
