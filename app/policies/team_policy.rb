class TeamPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def new?
    user.administrator? || user.corporate?
  end

  def create?
    new?
  end

  def edit?
    create?
  end

  def update?
    edit?
  end

  def show?
    user.admin? || user.agent?
  end

  def destroy?
    create?
  end

  def allowed_params
    valid_params = []
    valid_team_params = Team::ALLOWED_PARAMS
    valid_memberships_params = [{membership_attributes: TeamUser::ALLOWED_PARAMS }]
    return case
    when (user.administrator? || user.corporate?)
      valid_params = valid_team_params + valid_memberships_params
    when user.manager?
    else
      # NOOP
    end
    return valid_params
  end

end
