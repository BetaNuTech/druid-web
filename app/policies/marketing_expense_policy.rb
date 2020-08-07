class MarketingExpensePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      skope = scope
      return case user
      when ->(u) { u.admin? }
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

  def allowed_params
    valid_params = MarketingExpense::ALLOWED_PARAMS
    case user
    when ->(u) { u.admin? }
      # NOOP
    when  ->(u) { u.manager? }
      valid_params = []
    else
      valid_params = []
    end

    valid_params
  end
end
