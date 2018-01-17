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
    user === record || user.administrator? || (user.operator? && !record.administrator?)
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

  def allowed_params
    valid_user_params = User::ALLOWED_PARAMS
    valid_property_agent_params = [ { property_agent_attributes: PropertyAgent::ALLOWED_PARAMS } ]
    case user
    when ->(u) { u.administrator? }
      # NOOP all valid fields allowed
    when ->(u) { u.operator? }
      # NOOP all valid fields allowed
    when ->(u) { u.agent? }
      valid_user_params = valid_user_params - [:role_id]
      valid_property_agent_params = []
    else
      valid_user_params = []
      valid_property_agent_params = []
    end

    return(valid_user_params + valid_property_agent_params )

  end

end
