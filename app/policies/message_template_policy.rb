class MessageTemplatePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.
        includes(:message_type).
        where(message_templates: { user_id: [ user.id, nil ] }).
        order("message_types.name ASC, message_templates.name ASC")
    end
  end

  def index?
    user.admin? || user.user?
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    user.admin? || is_owner? || ( record.shared? && property_manager? )
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
    reject_params = []

    case user
    when ->(u) { u.admin? }
      # NOOP: Full permissions
    when ->(u) { u.user? }
      # Only limit params on existing MessageTemplates
      if record.is_a?(MessageTemplate) && !record.new_record?
        # Guard changing users
        unless change_user?
          reject_params << :user_id
        end
      end
    end

    valid_params = MessageTemplate::ALLOWED_PARAMS - reject_params
    return valid_params
  end

  def property_manager?
    record&.user&.present? &&
      record.user.properties.to_a.any?{|p| user.property_manager?(p)}
  end

  # Allow admin or MessageTemplate owner to reassign MessageTemplate to another User
  #  but disallow claiming another Agent's MessageTemplate
  def change_user?
    user.admin? || is_owner?
  end

end
