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
    @current_property.leads.where(user: @current_user).in_progress
  end

  def all_leads
    @current_property.leads.early_pipeline
  end

  def stale_leads
    @current_property.leads.stale
  end

  def upcoming_appointments
    @current_user.scheduled_actions.appointments.pending
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
