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
    user.admin? || user.agent?
  end

  def new?
    user.admin? || user.agent?
  end

  def create?
    new?
  end

  def show?
    is_owner? ||
      user.administrator? ||
      (user.admin? && same_property?)
  end

  def edit?
    record.draft? && ( user.administrator? || is_owner? )
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
    user.admin? || same_user
  end

  def same_property?
    record.try(:messageable).try(:present?) &&
      user.properties.include?(record.messageable.property)
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
