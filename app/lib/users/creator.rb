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
      @property_role = params[:property_role]
      @team = Team.find(params[:team_id]) rescue nil
      @teamrole = Teamrole.find(params[:teamrole_id]) rescue nil
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
      @user.errors.each{|e| @errors.add(e)} unless @user.valid?
      if @new_record
        if !@creator.present?
          @errors.add(:creator, "missing")
          @user.errors.add(:creator, "missing")
        end
        unless @user.role_id.present?
          @errors.add(:role_id, "is missing")
          @user.errors.add(:role_id, "is missing")
        end
        unless policy.assign_to_role?
          @errors.add(:role_id, "cannot be set by creator")
          @user.errors.add(:role_id, "cannot be set by creator")
        end
        if !@user.admin?
          unless @property.present?
            @errors.add(:property_id, "is missing")
            @user.errors.add(:property_id, "is missing")
          end
          unless PropertyUser.roles.keys.include?(@property_role)
            @errors.add(:property_role, "is invalid")
            @user.errors.add(:property_role, "is invalid")
          end
        end
        unless @team.present?
          @errors.add(:team_id, "is missing")
          @user.errors.add(:team_id, "is missing")
        end
        unless @teamrole.present?
          @errors.add(:teamrole_id, "is invalid")
          @user.errors.add(:teamrole_id, "is invalid")
        end
      end
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
      @errors&.keys.present? && @errors.keys.include?(attr.to_sym)
    end

    private

    def init_user
      @user = new_record? ? User.new : policy_scope.find(@user_id)
      @user_attributes = allowed_attributes(@params)
      @user.attributes = @user_attributes
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
