class UserPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user.admin? || user.user?
  end

  def new?
    user.admin? || user.manager?
  end

  def create?
    new?
  end

  def edit?
    case user
    when -> (u) { u === record }
      true
    when -> (u) { u.admin? }
      user.role >= record.role
    when -> (u) { u.team_admin? }
      (user.role >= record.role) &&
        (record.property.nil? ||
          same_property? ||
          team_lead?  )
    when -> (u) { property_manager? }
      user.role >= record.role && !record.manager?
    when -> (u) { u.manager? }
      (user.role >= record.role) &&
        (record.property.nil? ||
          same_property? ||
          team_lead?  )
    when -> (u) { team_lead? }
      user.role >= record.role && !record.manager?
    else
      false
    end
  end

  def update?
    edit?
  end

  def show?
    edit? ||
    user.admin? ||
    property_manager? ||
    team_lead?
   end

  def destroy?
    user != record && edit?
  end

  def impersonate?
    user.administrator? && !record.administrator?
  end

  def assign_to_role?
    manager_access =
      ( record.role.nil? && record.teamrole.nil? ) ||
      ( record.role.nil? && record.property.nil?) ||
      ( user.role >= record.role &&
          (property_manager? || team_lead?) )
    case user
    when ->(u) { user.admin? }
      true
    when -> (u) { u.manager? }
      manager_access
    when -> (u) { u.team_admin? }
      manager_access
    when -> (u) { property_manager? }
      manager_access
    when -> (u) { team_lead? }
      manager_access
    else
      false
    end
  end

  def assign_to_teamrole?
    case user
    when ->(u) { user.admin? }
      true
    when -> (u) { team_lead? }
      true
    when -> (u) { u.team_admin? }
      # Team admins can assign unaffiliated agents to their team
      record.teamrole.nil?
    else
      # Only Admins and team leads can assign teamroles
      false
    end
  end

  def allowed_params
    valid_user_params = User::ALLOWED_PARAMS
    valid_user_profile_params = [ { profile_attributes: UserProfile::ALLOWED_PARAMS } ]
    case user
    when ->(u) { u.administrator? }
      # NOOP all valid fields allowed
    when ->(u) { u.corporate? }
      # NOOP all valid fields allowed
    when ->(u) { u.manager? }
      # NOOP all valid fields allowed
    when ->(u) { u.property? }
      valid_user_params = valid_user_params - [:role_id, :teamrole_id]
    else
      valid_user_params = []
      valid_user_profile_params = []
    end

    return(valid_user_params + valid_user_profile_params)
  end

  def may_change_role?(new_role_id=nil)
    return false unless new_role_id.present?
    return false unless user.role.present?
    new_role = Role.where(id: new_role_id).first
    return false unless new_role.present?
    return user.role >= new_role
  end

  def may_change_teamrole?(new_role_id=nil)
    return user.admin?
  end

  def same_property?
    record.properties.any?{|rp| user.properties.include?(rp)}
  end

  def property_manager?
    record.properties.any?{|rp| user.property_manager?(rp) }
  end

  def team_lead?
    user.team_admin? && record.team == user.team
  end

  def user_is_a_manager?
    record.assignments.where(role: PropertyUser::MANAGER_ROLE).exists?
  end

end
