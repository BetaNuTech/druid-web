class PropertyPolicy < ApplicationPolicy

  def index?
    user.administrator? || user.operator? || user.agent?
  end

  def new?
    user.administrator? || user.operator?
  end

  def create?
    new?
  end

  def edit?
    user.administrator? || user.operator?
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
    valid_listing_params = [{listings_attributes: PropertyListing::ALLOWED_PARAMS}]
    valid_property_agent_params = [ { property_agent_attributes: PropertyAgent::ALLOWED_PARAMS } ]
    case user
    when ->(u) { u.administrator? }
      # NOOP all valid fields allowed
    when ->(u) { u.operator? }
      # NOOP all valid fields allowed
    when ->(u) { u.agent? }
      valid_property_params = []
      valid_listing_params = []
      valid_property_agent_params = []
    else
      valid_property_params = []
      valid_listing_params = []
      valid_property_agent_params = []
    end

    return(valid_property_params + valid_listing_params + valid_property_agent_params)

  end

end
