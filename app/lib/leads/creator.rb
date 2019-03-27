module Leads
  class Creator

    class Result
      attr_reader :status, :lead, :errors, :property_code

      def initialize(status:, lead:, errors:, property_code:)
        @status = status
        @lead = lead
        @errors= errors
        @property_code = property_code
      end
    end

    attr_reader :data,
      :errors,
      :lead,
      :parser,
      :saved,
      :source,
      :token,
      :agent

    def initialize(data:, agent: nil, token: )
      @lead = Lead.new
      @saved = false
      @errors = ActiveModel::Errors.new(Lead)
      @data = data
      @token = token
      @source = get_source(@token)
      @parser = get_parser(@source)
      @agent = agent
    end

    # Create lead from provided data using detected Source adapter
    def execute

      # Validate Access Token for Lead Source
      unless ( @source.present? && @token.present? )
        error_message =  "Invalid Access Token '#{@token}'}"
        @errors.add(:base, error_message)
        @lead.errors.add(:base, error_message)
        return @lead
      end

      # Validate Parser
      if @parser.nil?
        error_message =  "Parser for Lead Source not found: #{@source.try(:name) || 'UNKNOWN'}"
        @errors.add(:base, error_message)
        @lead.errors.add(:base, error_message)
        return @lead
      end

      parse_result = @parser.new(@data).parse

      @lead = Lead.new(parse_result.lead)
      @lead.user = @agent
      @lead.priority = "urgent"
      @lead.build_preference unless @lead.preference.present?
      @lead.source = @source
      @lead.first_comm = DateTime.now

      case parse_result.status
        when :ok
          @lead = assign_property(lead: @lead, property_code: parse_result.property_code)
          @lead.save
          property_assignment_warning(lead: @lead, property_code: parse_result.property_code)
        else
          @lead.validate
          parse_result.errors.each do |err|
            @lead.errors.add(:base, err)
          end
      end

      @errors = @lead.errors

      return @lead
    end

    private

    def assign_property(lead:, property_code: )
      if property_code.present?
        if (property = Property.find_by_code_and_source(code: property_code, source_id: @lead.source.id)).present?
          @lead.property_id = property.id
          err_message = nil
        end
      end
      return lead
    end

    # Log error if Lead property is not assigned
    def property_assignment_warning(lead:, property_code:)
      unless lead.property.present?
        err_message = "API WARNING: LEAD CREATOR COULD NOT IDENTIFY PROPERTY '#{property_code || '(None)'}' FROM SOURCE #{lead.source.try(:name)} FOR LEAD #{lead.id}"
        @lead.notes = "%s %s %s" % [@lead.notes, "///", err_message]
        @lead.save
        Rails.logger.warn err_message
      end
    end

    # Lookup Source by slug or default
    def get_source(token)
      return LeadSource.active.where(api_token: token).first
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
