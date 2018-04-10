class EngagementPolicyLoader
  attr_reader :data, :version, :errors

  def initialize(data)
    @errors = []
    case data
    when Hash
      @data = data
    when String
      @data = load_yaml(data)
    end
  end

  def call
    raise "EngagementPolicyLoader ERROR: #{@errors.join(',')}" unless valid?
    root = @data[:engagement_policy]
    version = root[:version]
    data = root[:data]

    ActiveRecord::Base.transaction do
      data = root[:data]
      data.each_with_index do |policy_record, index|
        version = policy_record[:version]
        property_name = policy_record[:property_name]
        lead_state = policy_record[:lead_state]
        active = policy_record[:active]
        description = policy_record[:description]

        property_id = nil
        unless ( property = Property.where(name: property_name).last).present?
          raise "Record[#{index}] Property named '#{property_name}' not found"
          property_id = property.id
        end unless property_name.nil?

        unless (Lead.state_names.include?(lead_state))
          raise "Record[#{index}] Lead State '#{lead_state}' is invalid"
        end

        old_policy = EngagementPolicy.
          where(lead_state: lead_state, property_id: property_id).
          order(version: "desc").first
        if old_policy.present?
          if old_policy.version >= version
            # Skip import if imported policy is the same or earlier version
            msg = " = EngagementPolicyLoader: '%s' Leads EngagementPolicy for '%s' is up-to-date with version #{old_policy.version} (skipping import)" %
              [old_policy.lead_state, (old_policy.property.present? ? old_policy.property.name : "default")]
            puts msg unless Rails.env.test?
            Rails.logger.warn msg
            next
          else
            if active
              # Set old policy to inactive if imported policy is active
              old_policy.active = false
            end
          end
          old_policy.save
          msg = " - EngagementPolicyLoader: Deprecated '#{old_policy.description}' version #{old_policy.version}"
          puts msg unless Rails.env.test?
          Rails.logger.warn msg
        end

        new_policy = EngagementPolicy.new(
          property_id: property_id,
          lead_state: lead_state,
          description: description,
          version: version,
          active: active
        )

        actions = policy_record[:engagement_policy_actions].map do |action_record|
          lead_action_name = action_record[:lead_action_name]
          lead_action = LeadAction.where(name: lead_action_name).last
          raise "EngagementPolicyLoader: Invalid LeadAction '#{lead_action_name}'" if lead_action.nil?

          EngagementPolicyAction.new(
            lead_action_id: lead_action.id,
            description: action_record[:description],
            deadline: action_record[:deadline],
            retry_count: action_record[:retry_count],
            retry_delay: action_record[:retry_delay],
            retry_delay_multiplier: action_record[:retry_delay_multiplier],
            score: action_record[:score],
            active: action_record[:active]
          )
        end

        new_policy.actions = actions
        new_policy.save!
        new_policy.reload
        msg = " + EngagementPolicyLoader: Created '#{new_policy.description}' version #{new_policy.version} with #{new_policy.actions.count} actions"
        new_policy.actions.each do |a|
          msg += "\n   + Task: #{a.lead_action.name}"
        end
        puts msg unless Rails.env.test?
        Rails.logger.warn msg
      end

    end
  end

  def valid?
    validate
    return @errors.empty?
  end

  private

  def validate
    @errors = []
    @errors << ":engagement root key not found" unless @data.keys.include?(:engagement_policy)
    root_node = @data[:engagement_policy]
    @errors << ":version key not found or invalid version" unless (@version = root_node.fetch(:version,0).to_i) > 0
    @errors << ":data key not found" if (engagement_policies = root_node.fetch(:data,[])).empty?
    return @errors
  end

  def load_yaml(filename)
    raise "EngagementPolicyLoader ERROR: #{filename} not found" unless File.exist?(filename)
    return YAML.load(File.read(filename))
  end
end
