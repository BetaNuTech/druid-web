class NotePolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      case user
        when ->(u) { u.administrator? }
          skope = scope
        else
          skope = scope.where(classification: ['comment', 'system' ])
      end
      skope = skope.order(created_at: :desc)
      return skope
    end
  end

  def index?
    user.admin?
  end

  def new?
    user.admin? || user.user?
  end

  def create?
    new?
  end

  def edit?
    user.admin? || (user.user? && ( same_user? || same_notable_user? ) )
  end

  def update?
    edit?
  end

  def show?
    user.admin? || user.user?
  end

  def destroy?
    edit?
  end

  def same_user?
    record.user.present? && record.user === user
  end

  def same_notable_user?
    record.notable.present? && record.notable.respond_to?(:user) &&
      record.notable.user === user
  end

  def allowed_params
    case
      when user.admin?
        allowed = Note::ALLOWED_PARAMS
      when user.user?
        allowed = Note::ALLOWED_PARAMS
        if record.respond_to?(:user) && record.user.present? && record.user != user
          allowed -= [:user_id]
        end
      else
      allowed = []
    end
    return allowed
  end


end
