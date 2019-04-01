class MessagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      skope = scope.order("created_at DESC")
      return case user
      when ->(u) { u.admin? }
        skope
      else
        skope.where(user_id: user.id)
      end
    end
  end

  def index?
    user.admin? || user.user?
  end

  def new?
    user.admin? || user.user?
  end

  def create?
    new?
  end

  def show?
    is_owner? || user.admin? || property_manager?
  end

  def edit?
    (record.respond_to?(:draft?) ? record.draft? : true ) &&
      (is_owner? || property_manager? || user.admin?)
  end

  def update?
    edit?
  end

  def destroy?
    record.draft? && edit?
  end

  def deliver?
    record.draft? && edit?
  end

  def mark_read?
    user.admin? || is_owner?
  end

  def same_property?
    record&.messageable&.present? &&
      user.properties.include?(record.messageable.property)
  end

  def property_manager?
    record&.messageable&.present? &&
      user.property_manager?(record.messageable.property)
  end

  def allowed_params
    return case
      when update?
        Message::ALLOWED_PARAMS
      else
        []
      end
  end
end
