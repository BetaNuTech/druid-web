class StatPolicy < ApplicationPolicy
  def manager?
    user.admin?
  end
end
