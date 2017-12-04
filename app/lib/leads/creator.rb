module Leads
  class Creator
    attr_reader :data,
      :errors,
      :lead,
      :parser,
      :saved,
      :source,
      :source_slug

    def initialize(data: params, source: 'Druid', agent: nil)
      @lead = Lead.new
      @saved = false
      @data = data
      @errors = ActiveModel::Errors.new(Lead)
      @source_slug = source
      @source = get_source(@source_slug)
      @parser = get_parser(@source)
    end

    def execute
      if @parser.nil?
        @errors.add(:base, "Parser for Lead Source not found: #{@source_slug}")
        @lead.validate
        return @lead
      end

      @lead = Lead.new(@parser.new(@data).parse)
      @lead.build_preference unless @lead.preference.present?
      @lead.source = @source
      @lead.save
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
      LeadSource.where(slug: source_slug).active.first
    end

    def default_source
      LeadSource.where(slug: 'Druid').active
    end

    def get_parser(source)
      return nil unless source
      return Leads::Adapters.valid_source?(source.slug) ?
        Object.const_get("Leads::Adapters::#{source.slug}") :
        nil
    end
  end
end
