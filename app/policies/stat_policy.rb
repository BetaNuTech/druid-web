class StatPolicy < ApplicationPolicy
  def manager?
    user.admin? || user.agent?
  end
end
