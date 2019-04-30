class MessagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      skope = scope
      skope = case user
        when ->(u) { u.admin? }
          skope
        # TODO: the following does not return expected Messages in MessagesController#index
        #when ->(u) { u.manager? }
          #skope.includes(user: :properties).
            #where(user_id: user.id).
            #or(skope.includes(user: :properties).
               #where(property_users: {property_id: user.properties.map(&:id)}))
        else
          skope.where(user_id: user.id)
        end
      return skope.display_order
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

  def body_preview?
    show?
  end

  def edit?
    record&.draft? &&
      (is_owner? || property_manager? || user.admin?)
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def deliver?
    edit?
  end

  def mark_read?
    user.admin? || is_owner?
  end

  def same_property?
    record&.messageable&.present? &&
      user&.properties&.include?(record.messageable.property)
  end

  def property_manager?
    record&.messageable&.property&.present? &&
      user&.property_manager?(record.messageable.property)
  end

  def allowed_params
    Message::ALLOWED_PARAMS
  end
end
