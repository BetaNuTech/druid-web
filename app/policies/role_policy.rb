class RolePolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
    end
  end


  def index?
    user.administrator?
  end

  def new?
    index?
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
    index?
  end

  def destroy?
    create?
  end

  def allowed_params
    case user
    when ->(u) { u.administrator? }
      Role::ALLOWED_PARAMS
    when ->(u) { u.corporate? }
      []
    when ->(u) { u.manager? }
      []
    when ->(u) { u.property? }
      []
    else
      []
    end
  end

end
