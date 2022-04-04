class HomeDashboard
  attr_reader :current_user, :params
  def initialize(current_user:, params:)
    @current_user = current_user
    @params = params
  end

  def unclaimed_leads
    Lead.for_agent(current_user).in_progress.is_lead
  end

  def my_leads
    # TODO
  end

  def all_leads
    # TODO
  end

  def stale_leads
    # TODO
  end

  def upcoming_appointments
    # TODO
  end

  def my_tasks
    # TODO
  end

  def all_tasks
    # TODO
  end

  def stats
    # TODO
  end
  
end
