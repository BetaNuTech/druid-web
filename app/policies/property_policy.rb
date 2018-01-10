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
    valid_listing_params = [{listings_attributes: PropertyListing::ALLOWED_PARAMS}]
    case user
    when ->(u) { u.administrator? }
      Property::ALLOWED_PARAMS + valid_listing_params
    when ->(u) { u.operator? }
      Property::ALLOWED_PARAMS + valid_listing_params
    when ->(u) { u.agent? }
      []
    end
  end

end
