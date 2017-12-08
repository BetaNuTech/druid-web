module Leads
  class Creator
    attr_reader :data,
      :errors,
      :lead,
      :parser,
      :saved,
      :source,
      :source_slug

    def initialize(data: params, source: nil, agent: nil)
      @lead = Lead.new
      @saved = false
      @data = data
      @errors = ActiveModel::Errors.new(Lead)
      @source_slug = source
      @source = get_source(@source_slug)
      @parser = get_parser(@source)
    end

    # Create lead from provided data using detected Source adapter
    def execute
      if @parser.nil?
        error_message =  "Parser for Lead Source not found: #{@source_slug}"
        @errors.add(:base, error_message)
        @lead.validate # and add errors
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


    def get_source(source_slug)
      return source_slug ?
        lookup_source(source_slug) :
        default_source
    end

    # Lookup LeadSource from provided slug
    def lookup_source(source_slug)
      LeadSource.active.where(slug: source_slug).first
    end

    def default_source
      LeadSource.active.where(slug: 'Druid').first
    end

    def get_parser(source)
      return nil unless source
      return Leads::Adapters.supported_source?(source.slug) ?
        Object.const_get("Leads::Adapters::#{source.slug}") :
        nil
    end
  end
end
