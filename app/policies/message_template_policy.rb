class MessageTemplatePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      skope = scope.includes(:message_type)
      skope = case user
        when ->(u) { u.admin?}
          # Return all
          skope
        when ->(u) { u.manager? }
          # Return shared or belonging to subordinates
          skope.where("message_templates.shared = true OR message_templates.user_id IN ( ? )", user.subordinates.map(&:id))
        else
          # Return shared or own
          skope.where("message_templates.shared = true OR message_templates.user_id IN ( ? )", user.id)
        end
      return skope.order("message_types.name ASC, message_templates.name ASC")
    end
  end

  def index?
    user.admin? || user.user?
  end

  def new?
    # Anyone can create
    index?
  end

  def create?
    # Anyone can create
    new?
  end

  def edit?
    # Owners, property managers, or admins can edit/update/delete
    is_owner? || property_manager? || user.admin?
  end

  def update?
    edit?
  end

  def show?
    record.shared? || is_owner? || property_manager? || user.admin?
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
    return false unless record.respond_to?(:user)
    record&.user&.present? &&
      record.user.properties.to_a.any?{|p| user.property_manager?(p)}
  end

  # Allow admin or MessageTemplate owner to reassign MessageTemplate to another User
  #  but disallow claiming another Agent's MessageTemplate
  def change_user?
    user.admin? || is_owner? || property_manager?
  end

  def users_for_reassignment
    case user
    when ->(u) {u.admin? || u.corporate?}
      users = User.includes(:profile)
    else
      if property_manager?
        users = user.subordinates
      else
        property_user_ids = PropertyUser.where(property_id: ( user.properties&.map(&:id)) || []).
          map(&:user_id).uniq
        users = User.includes(:profile).
          where(id: property_user_ids)
      end
    end
    return users.order("user_profiles.last_name ASC, user_profiles.first_name ASC")
  end

end
