class ResidentPolicy < ApplicationPolicy
  def index?
    user.admin? || user.user?
  end

  def new?
    index?
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
    valid_resident_params = Resident::ALLOWED_PARAMS
    valid_resident_detail_params = [ { detail_attributes: ResidentDetail::ALLOWED_PARAMS } ]
    _allowed_params = []

    case user
    when ->(u) { u.admin? || u.agent? }
      _allowed_params = valid_resident_params + valid_resident_detail_params
    end

    return _allowed_params
  end

end
