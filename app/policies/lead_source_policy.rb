class LeadSourcePolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user.admin?
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    user.admin?
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
    when ->(u) { u.corporate? }
      LeadSource::ALLOWED_PARAMS
    when ->(u) { u.manager? }
      []
    when ->(u) { u.property? }
      []
    end
  end

end
