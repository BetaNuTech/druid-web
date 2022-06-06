class HomeDashboard
  attr_reader :current_user, :params, :current_property

  def initialize(current_user:, current_property: nil, params:)
    @current_user = current_user
    @current_property = current_property || user.properties.first
    @params = params
  end

  def unclaimed_leads
    return Lead.where('1=0') unless @current_property.present?

    @current_property.leads.open
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
