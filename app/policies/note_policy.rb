class NotePolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def new?
    user.admin? || user.agent?
  end

  def create?
    new?
  end

  def edit?
    user.admin? || (user.agent? && record.user.present? && record.user === user  )
  end

  def update?
    edit?
  end

  def show?
    user.admin? || user.agent?
  end

  def destroy?
    edit?
  end

  def allowed_params
    allowed = []
    case
      when user.admin?
        allowed = Note::ALLOWED_PARAMS
      when user.agent?
        allowed = Note::ALLOWED_PARAMS
        if record.user.present? && record.user != user
          allowed -= [:user_id]
        end
    end
    return allowed
  end


end
