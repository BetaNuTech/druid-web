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

  def create_lead?
    user.admin? || same_property?
  end

  def duplicate_leads?
    user.admin? || same_property?
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
    case user
    when ->(u) { u.administrator? }
      # NOOP all valid fields allowed
    when ->(u) { u.corporate? }
      # NOOP all valid fields allowed
    when ->(u) { u.manager? }
      # NOOP all valid fields allowed
    when ->(u) { u.user? }
      valid_property_params = []
      valid_listing_params = []
      valid_phone_number_params = []
      valid_property_user_params = []
    else
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
