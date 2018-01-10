class UserPolicy < ApplicationPolicy

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
    user === record || user.administrator? || (user.operator? && !record.administrator?)
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

  def allowed_params
    case user
    when ->(u) { u.administrator? }
      User::ALLOWED_PARAMS
    when ->(u) { u.operator? }
      User::ALLOWED_PARAMS
    when ->(u) { u.agent? }
      User::ALLOWED_PARAMS - [:role_id]
    else
      []
    end
  end

end
