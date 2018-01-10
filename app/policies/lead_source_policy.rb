class LeadSourcePolicy < ApplicationPolicy

  def index?
    user.administrator? || user.operator?
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    user.administrator? || user.operator?
  end

  def update?
    edit?
  end

  def show?
    edit?
  end

  def destroy?
    edit?
  end

  def reset_token?
    edit?
  end

  def allowed_params
    case user
    when ->(u) { u.administrator? }
      LeadSource::ALLOWED_PARAMS
    when ->(u) { u.operator? }
      LeadSource::ALLOWED_PARAMS
    when ->(u) { u.agent? }
      []
    end
  end

end
