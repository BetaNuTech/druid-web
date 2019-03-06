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
    index?
  end

  def destroy?
    create?
  end

  def duplicate_leads?
    user.admin? || same_property?
  end

  def same_property?
    user.property_manager?(record) || user.property_agent?(record)
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
    when ->(u) { u.property_manager?(record) }
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

end
