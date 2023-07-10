class StatPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    manager?
  end

  def manager?
    user.admin? || user.user?
  end

  def report_csv?
    user.admin?
  end

  def lead_engagement_csv?
    user.admin?
  end

  def referral_bounces?
    user.admin?
  end
end
