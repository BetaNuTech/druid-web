class StatPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
    end
  end

  def manager?
    user.admin? || user.user?
  end
end
