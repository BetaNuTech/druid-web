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
    # Temporarily disabled
    return false
    user.admin? || user.user?
  end
end
