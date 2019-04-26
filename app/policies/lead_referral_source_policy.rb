class LeadReferralSourcePolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    index?
  end

  def new?
    user.admin?
  end

  def create?
    user.admin?
  end

  def edit?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def allowed_params
    return LeadReferralSource::ALLOWED_PARAMS
  end
end
