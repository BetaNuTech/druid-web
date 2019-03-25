class TeamPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
    end
  end

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
    create? || record.teamrole_for(user)&.lead?
  end

  def update?
    edit?
  end

  def show?
    user.admin? || user.property?
  end

  def destroy?
    create?
  end

  def assign_membership?
    user.administrator? || user.corporate? || record.teamrole_for(user)&.lead?
  end

  def add_member?
    assign_membership?
  end

  def allowed_params
    valid_params = []
    valid_team_params = Team::ALLOWED_PARAMS
    valid_memberships_params = [{memberships_attributes: TeamUser::ALLOWED_PARAMS }]
    return case
    when edit?
      valid_params = valid_team_params
      if assign_membership?
        valid_params += valid_memberships_params
      end
    else
      # NOOP
      # No params allowed
    end
    return valid_params
  end

end
