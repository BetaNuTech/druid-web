class UnitTypePolicy < ApplicationPolicy

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

  def show?
    index?
  end

  def edit?
    new?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def allowed_params
    return case
    when user.admin?
      UnitType::ALLOWED_PARAMS
    else
      []
    end
  end

end
