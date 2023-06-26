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
    @current_property.leads.where(user: @current_user).in_progress.
      order(last_name: :asc, first_name: :asc)
  end

  def all_leads
    @current_property.leads.early_pipeline.
      order(priority: :desc, last_name: :asc, first_name: :asc)
  end

  def stale_leads
    @current_property.leads.stale.
      order(last_name: :asc, first_name: :asc)
  end

  def upcoming_appointments
    @current_user.scheduled_actions.appointments.having_schedule.pending.
      order('schedules.date ASC')
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
