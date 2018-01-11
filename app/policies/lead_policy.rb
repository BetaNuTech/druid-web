class LeadPolicy < ApplicationPolicy

  # All users can view and modify Leads

  def index?
    user.administrator? || user.operator? || user.agent?
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

  def allowed_params
    reject_params = []

    case user
    when ->(u) { u.administrator? }
      # NOOP: Full permissions
    when ->(u) { u.operator? }
      # NOOP: Full permissions
    when ->(u) { u.agent? }
      # Only limit params on instantiated Leads
      if record.is_a?(Lead)
        # Disallow reassignment of lead source
        reject_params << :lead_source_id

        # Allow Lead owner to reassign Lead to another User
        #  but disallow claiming another Agent's Lead
        if record.user.present? && !( record.user === user )
          reject_params << :user_id
        end
      end
    end

    valid_lead_params = Lead::ALLOWED_PARAMS - reject_params
    valid_preference_params = [{preference_attributes: LeadPreference::ALLOWED_PARAMS }]
    return (valid_lead_params + valid_preference_params)
  end
end
