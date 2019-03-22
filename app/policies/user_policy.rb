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
    user === record ||
      (user.admin? && ( user.role >= record.role )) ||
      ( ( user.role >= record.role ) &&
        ( !record.manager? && property_manager? )
      )
  end

  def update?
    edit?
  end

  def show?
    user === record ||
      user.admin? ||
      property_manager?
  end

  def destroy?
    user != record && edit?
  end

  def assign_to_role?
    user.admin?
  end

  def assign_to_teamrole?
    user.admin?
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

  def user_is_a_manager?
    record.assignments.where(role: PropertyUser::MANAGER_ROLE).exists?
  end

end
