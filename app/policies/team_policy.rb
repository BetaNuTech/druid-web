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
    index?
  end

  def destroy?
    create?
  end

  def allowed_params
    return case
    when (user.administrator? || user.corporate?)
      Team::ALLOWED_PARAMS
    else
      []
    end
  end

end
