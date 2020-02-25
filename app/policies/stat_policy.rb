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
    # temporarily disabled
    return false
    user.admin? || user.user?
  end
end
