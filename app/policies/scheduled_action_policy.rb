class ScheduledActionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      skope = scope

      return case user
        when ->(u) {u.admin?}
          skope
        else
          if user.team.present?
            user_ids = user.team.memberships.map(&:user_id)
          else
            user_ids = [ user.id ]
          end
          skope.where(user_id: [ user_ids ])
        end
    end
  end

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
      same_user? ||
      (same_team? && !record.personal_task?)
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
      same_user? ||
      (same_team? && !record.personal_task?)
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

  def same_team?
    user.try(:team) == record.user.try(:team)
  end

  def same_user?
    record.user.present? && record.user === user
  end

  # Allow event to be issued if valid,
  #  current_user is admin, ScheduledAction owner, or same team
  def allow_state_event_by_user?(event_name)
    event = event_name.to_sym
    record.permitted_state_events.include?(event) &&
      (user.admin? || same_user? || same_team? )
  end
end
