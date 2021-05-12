class MarketingSourcePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      skope = scope
      return case user
      when ->(u) { u.admin?}
        skope
      when ->(u) { u.manager? }
        skope.where(property_id: user.managed_properties.pluck(:id))
      else
        skope.where('0=1')
      end
    end
  end

  def index?
    user.admin? || user.manager?
  end

  def new?
    user.admin?
  end

  def create?
    new?
  end

  def show?
    user.admin? || user.property_manager?(record.property)
  end

  def edit?
    user.admin?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def form_suggest_tracking_details?
    index?
  end

  def report?
    index?
  end

  def allowed_params
    valid_params = MarketingSource::ALLOWED_PARAMS
    case user
    when ->(u) { u.admin? }
      # NOOP
    when  ->(u) { u.manager? }
      # NOOP
    else
      valid_params = []
    end

    valid_params
  end

  def allowed_properties
    return case user
    when -> (u) { u.admin? }
      Property.order(name: :asc)
    when -> (u) { u.manager? }
      #user.managed_properties.order(name: :asc)
      []
    else
      []
    end
  end

  def select_property?
    allowed_properties.size > 1
  end

end
