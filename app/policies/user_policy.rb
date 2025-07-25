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
    user.admin? || (user.manager? && user.team.present?)
  end

  def edit?
    return false if record.system?
    
    case user
    when -> (u) { u === record }
      true
    when -> (u) { u.admin? }
      user.role >= record.role
    when -> (u) { team_lead? }
      user.role >= record.role && !record.manager?
    when -> (u) { u.team_admin? }
      (user.role >= record.role) &&
        (record.property.nil? ||
          same_property? ||
          team_lead?  )
    when -> (u) { property_manager? }
      user.role >= record.role &&
        !record.manager? &&
        !record.team_admin?
    when -> (u) { u.manager? }
      (user.role >= record.role) &&
        (!record.team_admin?) &&
        (record.property.nil? ||
          same_property? ||
          team_lead?  )
    else
      false
    end
  end

  def switch_setting?
    update?
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
    return false if record.system?
    
    !record.deactivated? &&
      user != record &&
      edit?
  end

  def impersonate?
    return false if record.system?
    
    !record.deactivated? && user.administrator? && !record.administrator?
  end

  def assign_to_role?
    manager_access =
      ( record.role.nil? && record.teamrole.nil? ) ||
      ( record.role.nil? && record.property.nil?) ||
      ( user.role >= record.role &&
          (property_manager? || team_lead?) )
    case user
    when nil
      false
    when ->(u) { user.admin? }
      true
    when -> (u) { u.manager? }
      manager_access
    when -> (u) { team_lead? }
      manager_access
    when -> (u) { u.team_admin? }
      manager_access
    when -> (u) { property_manager? }
      manager_access
    else
      false
    end
  end

  def allowed_params
    valid_user_params = User::ALLOWED_PARAMS
    valid_user_profile_params = [ { profile_attributes: UserProfile::ALLOWED_PARAMS + [ UserProfile::APPSETTING_PARAMS ] } ]
    case user
    when nil
      valid_user_params = []
      valid_user_profile_params = []
    when ->(u) { u.administrator? }
      # All valid fields allowed
      # Allow setting feature flags
      valid_user_profile_params = [ { profile_attributes: UserProfile::ALLOWED_PARAMS + [ UserProfile::FEATURE_PARAMS ] + [ UserProfile::APPSETTING_PARAMS ] } ]
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

    # Disallow self-deactivation
    if record == user
      valid_user_params = valid_user_params - [:deactivated]
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

  def manage_features?
    user&.administrator?
  end

  def same_property?
    record.properties.any?{|rp| user.properties.include?(rp)}
  end

  def property_manager?
    if record.new_record?
      user.property_manager?
    else
      record.properties.any?{|rp| user.property_manager?(rp) }
    end
  end

  def team_lead?
    user.team_admin? &&
      ( record.new_record? ||
       ( record.team == user.team ) )
  end

  def roles_for_select
    return Role.all.to_a.
      select{|role| user.role.present? ? user.role >= role : false}.
      map{|role| [role.name, role.id]}
  end

  def teamroles_for_select
    return Teamrole.all.to_a.map{|role| [role.name, role.id]}
  end

  def properties_for_select
    properties = case user
                 when -> (u) {u.admin?}
                   Property.active.all
                 when -> (u) {u.team_lead?}
                   (user.team.properties.active + user.properties.active).compact.uniq
                 when -> (u) {u.property_manager?}
                   user.properties.active
                 when -> (u) {u.agent?}
                   user.properties.active
                 end
    return properties.map{|p| [p.name, p.id]}.sort_by{|p| p[0]}
  end

  def property_roles_for_select
    return PropertyUser.roles.keys.map{|r| [r.humanize, r]}
  end

  def teams_for_select
    teams = case user
            when -> (u) {u.admin?}
              Team.order(name: :asc)
            else
              [user.team]
            end
    return teams.compact.map{|t| [t.name, t.id]}
  end

end
