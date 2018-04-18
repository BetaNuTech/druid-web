class ScheduledActionPolicy < ApplicationPolicy
  def index?
    user.admin? || user.agent?
  end

  def new?
    user.admin? || user.agent?
  end

  def create?
    new?
  end

  def edit?
    user.admin? ||
    ((record.user.present? && record.user === user) && record.personal_task?)
  end

  def update?
    edit?
  end

  def show?
    index?
  end

  def destroy?
    edit?
  end

  def completion_form?
    user.admin? ||
      ( record.user.present? &&
        record.user === user)
  end

  def complete?
    completion_form?
  end

  def allowed_params
    allowed = []
    case
      when user.admin?
        allowed = ScheduledAction::ALLOWED_PARAMS
      when user.agent?
        allowed = ScheduledAction::ALLOWED_PARAMS
        if record.respond_to?(:user) && record.user.present? && record.user != user
          allowed -= [:user_id]
        end
    end
    return allowed
  end
end
