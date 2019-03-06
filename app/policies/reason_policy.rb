class ReasonPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
    end
  end

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
    return case
    when user.admin?
      Reason::ALLOWED_PARAMS
    else
      []
    end
  end

end
