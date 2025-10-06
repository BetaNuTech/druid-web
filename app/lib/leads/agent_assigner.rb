module Leads
  class AgentAssigner

    class AgentAssignmentError < StandardError; end

    class AgentAssignment
      attr_reader :agent, :user, :lead, :errors, :id

      def self.collection_from_leads(leads:, user:)
        leads.map do |lead|
          AgentAssignment.new(
            user: user,
            agent: nil,
            lead: lead
          )
        end
      end

      def initialize(agent: nil, user: nil, lead: nil)
        @agent = agent
        @user = user
        @lead = lead
        @errors = nil
        @validated = false
        @id = SecureRandom.uuid
      end

      def validate
        params_present = @lead.present? && @agent.present? && @user.present?
        can_assign_agent = params_present && LeadPolicy.new(@user, @lead).change_user?
        valid_agent_for_assignment = params_present &&
                                     @agent.properties.include?(@lead.property) &&
                                     @user.properties.include?(@lead.property)

        @errors = []
        add_error "Invalid Lead Reference" unless @lead.present?
        add_error "Invalid Agent" unless @agent.present?
        add_error "Invalid Current User" unless @agent.present?
        add_error "Current User is not allowed to assign Lead agent" unless can_assign_agent
        add_error "Agent or Current User Property mismatch with Lead" unless valid_agent_for_assignment

        return @errors
      end

      def valid?
        validate if @errors.nil?
        return @errors.empty?
      end

      def save
        return false unless valid?

        if @lead.open?
          success = @lead.trigger_event(event_name: :work, user: @agent)
          add_error "Agent could not work Lead" unless success
        else
          add_error 'Mass re-assignment of working Leads is not supported'
        end

        return valid?
      end

      def reset_errors
        @errors = nil
      end

      def assignable_agents
        return @lead&.property&.users_available_for_lead_assignment || []
      end

      private

      def add_error(error)
        @errors ||= []
        @errors = @errors.push(error)
      end

    end

    attr_reader :user, :assignments, :errors, :property, :page, :leads, :last_assignments, :processed

    # Initialize with a user doing the assignment, and an array of hashes describing assignment data
    #
    # Ex: (user: User, leads: [Lead,...], assignments: [{agent_id: id, lead_id: id},...])
    def initialize(user:, property: nil, leads: [], assignments: [], page: 1)
      @user = user
      @leads = leads
      @property = property
      @errors = nil
      @all_agents = nil
      @all_leads = nil
      @page = page
      @assignments = assignments
      @processed = false
      preprocess!
    end

    def call
      validate and assign and continue
    end

    def valid?
      validate if @errors.nil?
      return @errors.empty?
    end

    def pending_assignment
      return @all_leads
    end

    private

    def continue
      if @assignments.present?
        @processed = true
        @last_assignments = @assignments
      else
        @processed = false
        @last_assignments = []
      end
      @assignments = []
      @leads = []
      preprocess!
      return true
    end

    def possible_property_leads
      return Lead.none unless @property

      @property.leads.open.ordered_by_created
    end

    # Pre-load Lead and User records for better performance
    def preprocess!
      @all_leads = possible_property_leads
      if @assignments.empty?
        if @leads.empty?
          if @property.present?
            # Assignments empty, leads empty, property present
            @leads = @all_leads.page(@page)
            @assignments = AgentAssignment.collection_from_leads(leads: @leads, user: @user)
          else
            # Assignments empty, leads empty, property missing
            return []
          end
        else
          # Assignments empty, leads present
          @assignments = AgentAssignment.collection_from_leads(leads: @leads, user: @user)
        end
      else
        # Assignments present
        # create assignments from provided assignments
        agent_ids = @assignments.map{|a| a[:agent_id]}.compact.uniq
        lead_ids = @assignments.map{|a| a[:lead_id]}.compact.uniq
        all_agents = User.where(id: agent_ids).
          inject({}){|memo, obj| memo[obj.id] = obj; memo}
        all_leads = Lead.where(id: lead_ids).
          inject({}){|memo, obj| memo[obj.id] = obj; memo}
        collection = @assignments.map do |assignment|
          agent = all_agents[assignment[:agent_id]]
          lead = all_leads[assignment[:lead_id]]
          # Ignore incomplete assignment records
          agent.present? && lead.present? ?
            AgentAssignment.new(user: @user, agent: agent, lead: lead) :
            nil
        end.compact
        @assignments = collection
      end
      unless @leads.respond_to?(:total_pages)
        # If the Lead collection is not paginated, make it so
        @leads = Lead.where(id: @leads.map(&:id)).page(@page)
      end
      return @assignments
    end

    def validate
      @errors = []
      @assignments.map! do |assignment|
        assignment.reset_errors
        add_assignment_errors(assignment) unless assignment.valid?
        assignment
      end
      return valid?
    end

    def assign
      return false unless valid?
      Lead.transaction do
        @assignments.map! do |assignment|
          unless assignment.save
            add_assignment_errors(assignment) unless assignment.save
            raise AgentAssignmentError.new("Error saving lead #{assignment.lead.id}: #{assignment.errors}")
          end
          assignment
        end
      end
      return valid?
    rescue AgentAssignmentError => error
      return false
    end

    def add_error(error)
      @errors ||= []
      @errors = @errors.push(error)
    end

    def add_assignment_errors(assignment)
      assignment.errors.each do |error|
        add_error({lead: assignment.lead, error: error})
      end
    end

  end
end
