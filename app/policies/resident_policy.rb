class ResidentPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      skope = scope
      return case user
      when -> (u) { u.admin? }
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
    user.admin? || user.user?
  end

  def create?
    new?
  end

  def show?
    user.admin? ||
      (user.user? && same_property?)
  end

  def edit?
    show?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def allowed_params
    valid_resident_params = Resident::ALLOWED_PARAMS
    valid_resident_detail_params = [ { detail_attributes: ResidentDetail::ALLOWED_PARAMS } ]

    case user
    when ->(u) { u.admin? || u.user? }
      _allowed_params = valid_resident_params + valid_resident_detail_params
    else
      _allowed_params = []
    end

    return _allowed_params
  end

  def same_property?
    record.property.present? &&
      ( user.property_manager?(record.property) || user.property_agent?(record.property))
  end

end
