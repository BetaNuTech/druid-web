class PropertyPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      skope = scope
      return case user
      when ->(u) { u.admin?}
        skope
      else
        skope.where(id: user.properties.map(&:id))
      end
    end
  end

  def index?
    user.agent? || user.admin?
  end

  def new?
    user.admin?
  end

  def create?
    new?
  end

  def edit?
    user.admin?
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

  def allowed_params
    valid_property_params = Property::ALLOWED_PARAMS
    valid_listing_params = [ { listings_attributes: PropertyListing::ALLOWED_PARAMS } ]
    valid_phone_number_params = [ { phone_numbers_attributes: PhoneNumber::ALLOWED_PARAMS } ]
    case user
    when ->(u) { u.administrator? }
      # NOOP all valid fields allowed
    when ->(u) { u.corporate? }
      # NOOP all valid fields allowed
    when ->(u) { u.manager? }
      # NOOP all valid fields allowed
    when ->(u) { u.agent? }
      valid_property_params = []
      valid_listing_params = []
      valid_property_agent_params = []
      valid_phone_number_params = []
    else
      valid_property_params = []
      valid_listing_params = []
      valid_property_agent_params = []
      valid_phone_number_params = []
    end

    return(valid_property_params + valid_listing_params + valid_phone_number_params)

  end

end
