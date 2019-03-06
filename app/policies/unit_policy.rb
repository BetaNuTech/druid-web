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
    user.admin? || user.user?
  end

  def new?
    user.admin? || user.manager?
  end

  def create?
    new?
  end

  def show?
    user.admin? ||
      (user.user? && same_property?)
  end

  def edit?
    user.admin? || property_manager?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def allowed_params
    return case user
      when ->(u) { user.admin? || property_manager? }
        Unit::ALLOWED_PARAMS
      else
        []
      end
  end

  def same_property?
    record.property.present? &&
      ( user.property_manager?(record.property) || user.property_agent?(record.property))
  end

  def property_manager?
    user.manager?
  end

end
