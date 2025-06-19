module Leads
  class Creator
    class Result
      attr_reader :status, :lead, :errors, :property_code, :parser

      def initialize(status:, lead:, errors:, property_code:, parser: nil)
        @status = status
        @lead = lead
        @errors = errors
        @property_code = property_code
        @parser = parser
      end
    end

    DEFAULT_TOKEN = '(NONE)'
    NOTE_LEAD_ACTION = 'External Referral'
    NOTE_REASON = 'Lead Referral'

    attr_reader :data,
                :errors,
                :lead,
                :parser,
                :saved,
                :source,
                :token,
                :agent,
                :status

    def self.create_event_note(message:, notable: nil, error: false)
      classification = error ? 'error' : 'external'

      lead_action = LeadAction.where(name: NOTE_LEAD_ACTION).first
      reason = Reason.where(name: NOTE_REASON).first
      content = message

      Note.create(
        classification: classification,
        lead_action: lead_action,
        reason: reason,
        notable: notable,
        content: content
      )
    end

    # Get Parser Class named like the Source slug
    def self.get_parser(source)
      return nil unless source

      Leads::Adapters.supported_source?(source.slug) ? Object.const_get("Leads::Adapters::#{source.slug}") : nil
    end

    def initialize(data:, agent: nil, token: DEFAULT_TOKEN)
      @lead = Lead.new
      @saved = false
      @errors = ActiveModel::Errors.new(Lead.new)
      @data = data
      @token = token
      @source = get_source(@token)
      @parser = get_parser(@source)
      @agent = agent
      @status = nil
    end

    # Create lead from provided data using detected Source adapter
    #
    # NOTE: the next major functional point is mark_duplicates and after_mark_duplicates
    # which are triggered from an after_create callback in Leads::Duplicates concern
    def call
      ### Validate Access Token for Lead Source
      unless @source.present? && @token.present?
        error_message = "Leads::Creator Error Invalid Access Token '#{@token}'}"
        @errors.add(:base, error_message)
        @lead.errors.add(:base, error_message)
        Leads::Creator.create_event_note(message: error_message, error: true)
        return @lead
      end

      ### Validate Parser
      if @parser.nil?
        error_message = "Leads::Creator Error Parser for Lead Source not found: #{@source.try(:name) || 'UNKNOWN'}"
        @errors.add(:base, error_message)
        @lead.errors.add(:base, error_message)
        @data.to_s
        Leads::Creator.create_event_note(message: error_message, error: true)
        return @lead
      end

      ### Parse incoming data
      begin
        parse_result = @parser.new(@data).parse
        @status = parse_status = parse_result.status
        add_parse_errors(parse_result)
      rescue StandardError => e
        @status = :error
        add_parse_errors(parse_result) if defined?(parse_result)
        @errors.add(:base, e.to_s)
        note_message = "Leads::Creator Error parsing incoming Lead data: #{e}\n\n#{@data}"
        Leads::Creator.create_event_note(message: note_message, error: true)
        lead = Lead.new
        @errors.full_messages.each { |e| lead.errors.add(:base, e) }
        return lead
      end

      ### Build lead from parser data
      @lead = Lead.new(parse_result.lead)

      ### Assign source first (needed for property assignment)
      @lead.source = @source

      ### Assign property early for resident validation
      if parse_result.property_code.present?
        @lead = assign_property(lead: @lead, property_code: parse_result.property_code)
      end

      ### Check for resident match for all lead sources
      if @lead.property.present?
        validator = Leads::ResidentValidator.new(
          property: @lead.property,
          lead_data: {
            first_name: @lead.first_name,
            last_name: @lead.last_name,
            phone1: @lead.phone1,
            phone2: @lead.phone2,
            email: @lead.email
          }
        )

        if validator.resident_match?
          matching_resident = validator.matching_resident
          error_message = 'This lead matches an existing resident'
          error_details = []

          # Build specific error details based on what matched
          if matching_resident['phone1'] == @lead.phone1 && @lead.phone1.present?
            error_details << "phone: #{@lead.phone1}"
          elsif matching_resident['phone2'] == @lead.phone2 && @lead.phone2.present?
            error_details << "phone: #{@lead.phone2}"
          elsif matching_resident['email'] == @lead.email && @lead.email.present?
            error_details << "email: #{@lead.email}"
          end

          full_error = "#{error_message} [#{error_details.join(', ')}]"
          @lead.errors.add(:base, full_error)
          @errors = @lead.errors

          # Log the rejection
          note_message = "Leads::Creator blocked lead creation - matched resident ID: #{matching_resident['resident_id']} - #{full_error}"
          Leads::Creator.create_event_note(message: note_message, notable: @lead.property, error: true)

          return @lead
        end
      end

      ### Additional check for duplicate leads by phone (kept for backwards compatibility)
      if @source.phone_source? && @lead.phone1.present? && Lead.where(phone1: @lead.phone1).any?
        @lead.errors.add(:phone1, "This lead matches the phone number of an existing recent lead [#{@lead.phone1}]")
        @errors = @lead.errors
        @lead.phone1 = nil
        @lead.phone2 = nil
        return @lead
      end

      ### Assign additional meta-data
      @lead.user = @agent if @agent.present?
      @lead.priority = 'urgent'
      @lead.build_preference unless @lead.preference.present?
      @lead.first_comm ||= DateTime.current

      case parse_status
      when :ok
        @lead.state = 'showing' if @lead.show_unit.present?
        valid_lead = @lead.save

        unless valid_lead
          @lead.errors.full_messages.each { |e| @errors.add(:base, e) }
          return @lead
        end

        # Make the walkin lead note a 'comment'
        if @data.fetch(:entry_type, '') == 'walkin'
          Note.create(user_id: @lead.user.id, notable: @lead, content: @lead.notes)
          @lead.notes = nil
          @lead.save
        end

        property_assignment_warning(lead: @lead, property_code: parse_result.property_code)
        if junk?(@lead)
          @lead = process_junk(@lead)
        else
          @lead.infer_referral_record
          @lead.update_showing_task_unit(@lead.show_unit) if @lead.state == 'showing'
        end
      when :async_processing
        # For async processing (e.g., OpenAI parser), no lead is created here
        # The lead will be created by the background job
        # Return an empty lead object that won't be saved
        @lead = Lead.new
        @lead.errors.add(:base, 'Lead is being processed asynchronously')
        return @lead
      when :invalid
        @lead.validate
        parse_result.errors.each do |err|
          @lead.errors.add(:base, err)
        end
        @lead.errors.full_messages.each { |e| @errors.add(:base, e) }
        notable = if parse_result.property_code.present?
                    Leads::Adapters::YardiVoyager.property(parse_result.property_code)
                  end
        note_message = 'Leads::Creator Error New Lead has validation errors: ' + @lead.errors.to_a.join(', ')
        Leads::Creator.create_event_note(message: note_message, notable: notable, error: true)
      end

      @lead
    end

    private

    def add_parse_errors(parse_result)
      return unless parse_result&.errors&.present?

      parse_errors = parse_result.errors
      parse_errors.each { |e| @errors.add(:base, e) }
    end

    def junk?(lead)
      lead.referral == 'Null'
    end

    def process_junk(lead)
      lead.classification = 'parse_failure'
      lead.disqualify
      lead.save
      lead
    end

    def assign_property(lead:, property_code:)
      if property_code.present?
        property = Property.find_by_code_and_source(code: property_code, source_id: lead.source.id)
        if lead.source == LeadSource.default
          # Fail over to finding Property By ID if using the default LeadSource (Bluesky WebApp)
          # for compatibility when creating a Lead via the Web UI
          property ||= Property.where(id: property_code).first
        end
        if property.present?
          lead.property_id = property.id
          nil
        end
      end
      lead
    end

    # Log error if Lead property is not assigned
    def property_assignment_warning(lead:, property_code:)
      return if lead.property.present?

      err_message = "Leads::Creator Error API WARNING: LEAD CREATOR COULD NOT IDENTIFY PROPERTY '#{property_code || '(None)'}' FROM SOURCE #{lead.source.try(:name)} FOR LEAD #{lead.id}"
      @lead.notes = format('%s %s %s', @lead.notes, '///', err_message)
      @lead.save
      Rails.logger.warn err_message
      Leads::Creator.create_event_note(message: err_message, error: true)
    end

    # Lookup Source by slug or default
    def get_source(token)
      return LeadSource.default if token == DEFAULT_TOKEN

      LeadSource.active.where(api_token: token).first
    end

    # Get Parser Class named like the Source slug
    def get_parser(source)
      Leads::Creator.get_parser(source)
    end
  end
end
