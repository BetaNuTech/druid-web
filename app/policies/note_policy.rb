class NotePolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope.
        where(user_id: user.id).
        order(created_at: "DESC")
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
    user.admin? || (user.user? && same_user? )
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

  def allowed_params
    allowed = []
    case
      when user.admin?
        allowed = Note::ALLOWED_PARAMS
      when user.user?
        allowed = Note::ALLOWED_PARAMS
        if record.respond_to?(:user) && record.user.present? && record.user != user
          allowed -= [:user_id]
        end
    end
    return allowed
  end


end
