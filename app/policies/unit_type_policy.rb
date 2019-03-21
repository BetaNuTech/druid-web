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
    user.admin? || user.manager?
  end

  def create?
    new?
  end

  def show?
    user.admin? || same_property?
  end

  def edit?
    user.admin? ||
      property_manager?
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

  def property_manager?
    user.property_manager?(record.property)
  end

  def same_property?
    user.assignments.where(property_id: record.property_id).exists?
  end

end
