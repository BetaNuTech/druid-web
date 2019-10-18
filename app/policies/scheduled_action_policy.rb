class ScheduledActionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      skope = scope

      return case user
        when ->(u) {u.admin?}
          skope
        when ->(u) { u.user? }
          if user.property.present?
            user_ids = user.assigned_properties_agent_ids
          else
            user_ids = [ user.id ]
          end
          skope.where(user_id: user.id).or(
            skope.where(user_id: [ user_ids ], target_type: 'Lead')
          )
        end
    end
  end

  def index?
    user.admin? || user.user?
  end

  def new?
    user.admin? || user.user?
  end

  def create?
    new?
  end

  def edit?
    !record.completed? &&
    ( user.admin? ||
      same_user? ||
      (user.user? &&
       (for_lead_in_same_property? && !record.personal_task?)) )
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

  def update_scheduled_action_form_on_action_change?
    edit?
  end

  def load_notification_template?
    edit?
  end

  def completion_form?
    same_user? ||
      user.manager? ||
      user.admin? ||
      (user.user? && (for_lead_in_same_property? && !record.personal_task?))
  end

  def complete?
    completion_form?
  end

  def impersonate?
    !same_user? && property_manager_for_lead?
  end

  def allowed_params
    allowed = []
    case
      when user.admin?
        allowed = ScheduledAction::ALLOWED_PARAMS
      when user.user?
        allowed = ScheduledAction::ALLOWED_PARAMS
        if record.respond_to?(:user) && record.user.present? && record.user != user
          allowed -= [:user_id]
        end
    end
    unless impersonate?
      allowed -= [:impersonate]
    end
    return allowed
  end

  def for_lead_in_same_property?
    record.target_type == 'Lead' && user.properties.map(&:id).include?(record.target.property.id)
  end

  def property_manager_for_lead?
    record.target_type == 'Lead' &&
    record.target.property.present? &&
    user.property_manager?(record.target.property)
  end

  def same_user?
    return true unless record.respond_to?(:user)
    record.user.present? && record.user === user
  end

  # Allow event to be issued if valid,
  #  current_user is admin, ScheduledAction owner, or same team
  def allow_state_event_by_user?(event_name)
    event = event_name.to_sym
    record.permitted_state_events.include?(event) &&
      (user.admin? || same_user? || for_lead_in_same_property? )
  end

  def conflict_check?
    same_user?
  end
end
