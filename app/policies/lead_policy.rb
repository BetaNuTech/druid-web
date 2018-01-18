class LeadPolicy < ApplicationPolicy

  # All users can view and modify Leads

  def index?
    user.admin? || user.user?
  end

  def show?
    index?
  end

  def new?
    index?
  end

  def create?
    index?
  end

  def edit?
    index?
  end

  def update?
    index?
  end

  def destroy?
    index?
  end

  def trigger_state_event?
    edit?
  end

  # Allow event to be issued if valid,
  #  current_user is admin, no user is associated with lead,
  #  or current_user owns lead
  def allow_state_event_by_user?(event_name)
    event = event_name.to_sym
    record.permitted_state_events.include?(event) &&
      (user.admin? || !record.user.present? || same_user? )
  end

  # Return an array of state events that the User can issue
  # to the Record
  def permitted_state_events
    record.permitted_state_events.
      select{|e| allow_state_event_by_user?(e) }
  end

  def same_user?
    record.user === user
  end

  def allowed_params
    reject_params = []

    case user
    when ->(u) { u.admin? }
      # NOOP: Full permissions
    when ->(u) { u.agent? }
      # Only limit params on existing Leads
      if record.is_a?(Lead) && !record.new_record?
        # Disallow reassignment of lead source
        reject_params << :lead_source_id

        # Guard changing users
        unless change_user?
          reject_params << :user_id
        end
      end
    end

    valid_lead_params = Lead::ALLOWED_PARAMS - reject_params
    valid_preference_params = [{preference_attributes: LeadPreference::ALLOWED_PARAMS }]
    return (valid_lead_params + valid_preference_params)
  end

  # Allow admin or Lead owner to reassign Lead to another User
  #  but disallow claiming another Agent's Lead
  def change_user?
    user.admin? || same_user?
  end
end
