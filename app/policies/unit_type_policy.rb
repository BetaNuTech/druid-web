class UnitTypePolicy < ApplicationPolicy
  def index?
    user.admin? || user.agent?
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
