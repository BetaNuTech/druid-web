class HomePolicy < ApplicationPolicy

  def index?
    user.admin? || user.manager? || user.agent?
  end

  def dashboard?
    index?
  end

  def manager_dashboard?
    index?
  end

  def messaging_preferences?
    true
  end

  def unsubscribe?
    true
  end

  def insert_open_lead?
    user.admin? || user.agent?
  end

end
