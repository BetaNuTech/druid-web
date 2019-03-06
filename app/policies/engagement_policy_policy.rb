class EngagementPolicyPolicy < ApplicationPolicy
  def index?
    user.admin? || user.user?
  end

  def new?
    user.admin?
  end

  def create?
    new?
  end

  def edit?
    new?
  end

  def update?
    edit?
  end

  def show?
    user.admin? || user.user?
  end

  def destroy?
    edit?
  end

  def allowed_params
    return []
  end

end
