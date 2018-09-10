class UserPolicy < ApplicationPolicy

  def index?
    user.admin?
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    user === record || user.admin?
  end

  def update?
    edit?
  end

  def show?
    edit?
  end

  def destroy?
    edit?
  end

  def assign_to_property?
    user.admin?
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
    when ->(u) { u.agent? }
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

end
