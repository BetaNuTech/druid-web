module Users
  class Creator
    attr_reader :errors, :user, :params, :user_attributes, :creator
    attr_accessor :property, :property_role, :team, :teamrole, :user_attributes

    # params:
    #
    # {
    #   user: {..., profile_attributes: ...},
    #   id: xxx,
    #   property_id: xxx,
    #   property_role: xxx,
    #   team_id:,
    #   teamrole_id:,
    # }
    def initialize(params:, creator: nil)
      @params = params
      @user_id = params[:id]
      @new_record = !User.where(id: @user_id).exists?
      @creator = creator
      @property = Property.find(params[:property_id]) rescue nil
      @property_role = params[:property_role] || PropertyUser::AGENT_ROLE
      @team = ( params[:team_id] ? Team.find(params[:team_id]) : @property&.team ) rescue nil
      @teamrole = (params[:teamrole_id] ? Teamrole.find(params[:teamrole_id]) : (@property.present? ? Teamrole.agent : nil)) rescue nil
      @errors = nil
      init_user
    end

    def policy
      return Policy.new(@creator, @user || User)
    end

    def policy_scope
      return Policy::Scope.new(@creator, User).resolve
    end

    def valid?
      unless @errors.nil?
        !@errors.any?
      else
        validate
        valid?
      end
    end

    def validate
      @errors = ActiveModel::Errors.new(User.new)
      @user.validate
      @user.errors.full_messages.each{|e| @errors.add(:base, e)} unless @user.valid?

      # Only apply these extended validations on a new record
      if @new_record
        # Creator present?
        if @creator.present?
          # OK
          true
        else
          @errors.add(:creator, "missing")
          @user.errors.add(:creator, "missing")
        end

        # Role present?
        if @user.role_id.present?
          # OK
          true
        else
          @errors.add(:role_id, "is missing")
          @user.errors.add(:role_id, "is missing")
        end

        # Can creator set role?
        if policy.assign_to_role?
          # OK
          true
        else
          @errors.add(:role_id, "cannot be set by creator")
          @user.errors.add(:role_id, "cannot be set by creator")
        end

        # Property present?
        if @property.present?
          # OK
          true
        else
          if @user.role&.admin?
            # Admins are ok
          else
            if @teamrole == Teamrole.lead
              # Team Leads are ok
            else
              @errors.add(:property_id, "is missing")
              @user.errors.add(:property_id, "is missing")
            end
          end
        end

        # Property Role present/valid?
        if PropertyUser.roles.keys.include?(@property_role)
          # OK
          true
        else
          if @user.role&.admin?
            # Admins are ok
          else
            if @teamrole == Teamrole.lead
              # Team Leads are ok
            else
              @errors.add(:property_role, "is invalid")
              @user.errors.add(:property_role, "is invalid")
            end
          end
        end

        # Team present?
        if @team.present?
          # OK
          true
        else
          if @user.role&.admin?
            # Admins are OK
            true
          else
            @errors.add(:team_id, "is missing")
            @user.errors.add(:team_id, "is missing")
          end
        end

        # Team Role present?
        if @teamrole.present?
          # OK
          true
        else
          if @user.role&.admin?
            # Admins are OK
            true
          else
            @errors.add(:teamrole_id, "is invalid")
            @user.errors.add(:teamrole_id, "is invalid")
          end
        end
      end # new_record?

      return @errors.any? ? @errors : true
    end

    def new_record?
      @new_record
    end

    def save
      return false unless valid?
      valid_transaction = false
      @user.transaction do
        @user.save!
        assign_property!
        assign_team!
        valid_transaction = true
      end
      return valid_transaction ? @user : false
    end

    def roles_for_select
      return policy.roles_for_select
    end

    def properties_for_select
      return policy.properties_for_select
    end

    def property_roles_for_select
      return policy.property_roles_for_select
    end

    def teamroles_for_select
      return policy.teamroles_for_select
    end

    def assign_to_role?
      return policy.assign_to_role?
    end

    def assign_teamrole?
      return policy.assign_to_role?
    end

    def teams_for_select
      return policy.teams_for_select
    end

    def error_for?(attr)
      return false unless @errors.present?

      error_data = @errors.to_hash
      error_data&.keys.present? && error_data.keys.include?(attr.to_sym)
    end

    private

    def init_user
      @user = new_record? ? User.new : policy_scope.find(@user_id)
      @user.timezone = 'Central Time (US & Canada)' if new_record?
      @user_attributes = allowed_attributes(@params)
      @user.attributes = @user_attributes
      @user.profile ||= UserProfile.new
      @user.profile.appsettings = @user.profile.appsettings_with_missing
      @user.profile.enabled_features = UserProfile.default_features.merge(@user.profile.enabled_features)
      return @user
    end

    def allowed_attributes(in_params)
      params = case in_params
        when Hash
          ActionController::Parameters.new(in_params)
        when ActionController::Parameters
          in_params
        end
      # Do not require password confirmation if password is not provided
      if params[:user].present?
        if params[:user][:password].blank?
          params[:user].delete(:password)
          params[:user].delete(:password_confirmation)
        end
      end

      # Determine Allowed User params by Policy
      valid_user_params = Policy.new(@creator, User).allowed_params

      unless new_record?
        policy = Policy.new(@creator, @user)
        # Prevent privilege escalation of Role
        unless policy.may_change_role?((params[:user][:role_id] rescue nil))
          valid_user_params = valid_user_params - [:role_id]
        end

        # Prevent privilege escalation of TeamRole
        unless policy.may_change_teamrole?((params[:user][:teamrole_id] rescue nil))
          valid_user_params = valid_user_params - [:teamrole_id]
        end
      end

      if params.keys.include?("user")
        allow_params = params.require(:user).permit(*valid_user_params)
      else
        allow_params = {}
      end

      return allow_params
    end

    def assign_team!
      if @team && @teamrole
        membership = TeamUser.create!(team: @team, user: @user, teamrole: @teamrole)
      end
    end

    def assign_property!
      if @property && @property_role.present?
        assignment = PropertyUser.create!(property: @property, user: @user, role: @property_role)
      end
    end

  end
end
