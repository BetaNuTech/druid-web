class PropertyPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      skope = scope
      return case user
      when ->(u) { u.admin?}
        skope
      when ->(u) { u.manager? }
        skope
      when ->(u) { u.team_lead? }
        skope
      else
        skope.where(id: user.properties.map(&:id))
      end
    end
  end

  def index?
    user.admin? || user.user?
  end

  def new?
    user.admin?
  end

  def create?
    new?
  end

  def edit?
    user.admin? || user.property_manager?(record)
  end

  def update?
    edit?
  end

  def show?
    user.admin? || user.manager? || same_property?
  end

  def destroy?
    create?
  end

  def user_stats?
    user.admin? || (user.manager? && same_property?)
  end

  def create_lead?
    user.admin? || same_property?
  end

  def duplicate_leads?
    user.admin? || same_property?
  end

  def edit_messages?
    # Allow admins, property managers, and property agents to edit automatic messages
    user.admin? || user.property_manager?(record)
  end

  def same_property?
    return false if record.nil?
    user.property_manager?(record) || user.property_agent?(record) || team_lead?
  end

  def team_lead?
    user.team_lead? && record.team == user.team
  end

  def allowed_params
    valid_property_params = Property::ALLOWED_PARAMS
    valid_listing_params = [ { listings_attributes: PropertyListing::ALLOWED_PARAMS } ]
    valid_phone_number_params = [ { phone_numbers_attributes: PhoneNumber::ALLOWED_PARAMS } ]
    valid_property_user_params = [ {property_users_attributes: PropertyUser::ALLOWED_PARAMS}]

    # If user can edit the property, they should be able to update its fields
    if edit?
      case user
      when ->(u) { u.administrator? }
        valid_property_params += [ Property::APPSETTING_PARAMS ]
      when ->(u) { u.corporate? }
        valid_property_params += [ Property::APPSETTING_PARAMS ]
      when ->(u) { u.manager? }
        valid_property_params += [ Property::APPSETTING_PARAMS ]
      # Property managers can edit basic fields but not app settings
      when ->(u) { u.property_manager?(record) }
        # Keep the basic property params (including file uploads)
        # but don't add APPSETTING_PARAMS
      else
        # For other cases where edit? is true but no specific role matches,
        # still allow basic property params
      end
    else
      # User cannot edit this property at all
      valid_property_params = []
      valid_listing_params = []
      valid_phone_number_params = []
      valid_property_user_params = []
    end

    return(valid_property_params + valid_listing_params + valid_phone_number_params + valid_property_user_params)

  end

  def subscribe_incoming_leads_channel?
    user.admin? || same_property?
  end

  def subscribe_incoming_messages_channel?
    ( user.admin? || same_property? ) && user.monitor_all_messages?
  end

  def for_lead_assignment
    return case user
    when ->(u) { u.nil? }
      Property.where('1=0')
    when ->(u) { u.admin? }
      Scope.new(user, Property).resolve.active
    when ->(u) { u.team_lead? }
      user.team.properties.active
    else
      user.properties.active
    end
  end

  def leads_accessible?
    return case user
      when ->(u) { u.administrator? }
        true
      when -> (u) { u.corporate? }
        true
      when ->(u) { u.team_lead? }
        true
      else
        user.properties.include?(record)
      end
  end

  def select_current?
    for_lead_assignment.count > 1
  end

end
