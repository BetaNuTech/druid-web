class UnitPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      skope = scope
      return case user
      when ->(u) { u.admin?}
        skope
      else
        skope.where(property_id: user.properties.map(&:id))
      end
    end
  end

  def index?
    user.admin? || user.agent?
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
    user.admin? || user.agent?
  end

  def destroy?
    edit?
  end

  def allowed_params
    return case
    when user.admin?
      Unit::ALLOWED_PARAMS
    else
      []
    end
  end

end
