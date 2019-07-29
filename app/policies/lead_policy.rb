class LeadPolicy < ApplicationPolicy

  class Scope < Scope
    EXCLUSIVITY_LIMIT=2
    def resolve
      skope = scope
      return case user
        when ->(u) { u.admin? }
          skope
        when -> (u) { u.team_lead?}
          skope.for_team(user.team)
        else
          # Belonging to User
          skope.where(user_id: user.id).
            # or Belonging to User's Team
            or(skope.where(property_id: user.properties.select(:id).map(&:id)))
            # or Open Leads older than EXCLUSIVITY_LIMIT
            #or(skope.where(state: 'open').where("leads.created_at < ?", EXCLUSIVITY_LIMIT.hours.ago))
        end
    end
  end

  # All users can view and modify Leads

  def index?
    user.admin? || user.user?
  end

  def search?
    index?
  end

  def show?
    user.admin? || is_owner? || same_property? || team_lead?
  end

  def call_log_partial?
    show?
  end

  def new?
    index?
  end

  def create?
    index?
  end

  def edit?
    show?
  end

  def update?
    edit?
  end

  def destroy?
    user.admin? || is_owner? || property_manager? || team_lead?
  end

  def trigger_state_event?
    edit?
  end

  def progress_state?
    edit?
  end

  def update_state?
    progress_state?
  end

  def compose_message?
    show? && record.message_types_available.present?
  end

  def mark_messages_read?
    user.admin? || is_owner?
  end

  def show_import_notes?
    user.admin?
  end

  # Allow event to be issued if valid,
  #  current_user is admin, no user is associated with lead,
  #  or current_user owns lead
  def allow_state_event_by_user?(event_name)
    event = event_name.to_sym
    record.permitted_state_events.include?(event) &&
      (!record.user.present? || is_owner? ||
       user.admin? || property_manager? || team_lead?)
  end

  def manually_change_state?
    user.admin? || property_manager?
  end

  def update_referrable_options?
    edit?
  end

  # Return an array of state events that the User can issue
  # to the Record
  def permitted_state_events
    record.permitted_state_events.
      select{|e| allow_state_event_by_user?(e) }
  end

  def allowed_params
    reject_params = []

    case user
    when ->(u) { u.admin? }
      # NOOP: Full permissions
    when ->(u) { u.user? }
      # Only limit params on existing Leads
      if record.is_a?(Lead) && !record.new_record?
        # Disallow reassignment of lead source
        reject_params << :lead_source_id

        # Guard changing users
        unless change_user?
          reject_params << :user_id
        end

        # Guard manually changing state
        unless manually_change_state?
          reject_params << :state
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
    is_owner? || user.manager? || user.admin?
  end


end
