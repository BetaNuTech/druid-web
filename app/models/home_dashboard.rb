class HomeDashboard
  attr_reader :current_user, :params, :current_property

  UserStats = Struct.new(:tenacity, :lead_speed, :start_date)

  DISPLAYED_TASKS = [
    'Assign New Resident Tasks',
    'Claim Lead',
    'Deliver Application',
    'Email Rental Application',
    'First Contact',
    'Make Appointment Notes',
    'Make Call',
    'Make Contact Notes',
    'Meeting',
    'Move-In Task',
    'Other',
    'Prepare Application',
    'Process Application',
    'Request Appointment',
    'Schedule Appointment',
    'Send Email',
    'Send SMS',
    'Show Unit',
    'Unit Inspection'
  ].freeze

  def initialize(current_user:, current_property: nil, params:)
    @current_user = current_user
    @current_property = current_property || user.properties.first
    @params = params
    @stats = nil
  end

  # Returns all unclaimed leads for the current property
  # if current_property is present otherwise it returns no leads.
  # 
  # @return [ActiveRecord::Relation] Returns ActiveRecord relation of unclaimed leads.
  # 
  def unclaimed_leads
    return Lead.where('1=0') unless @current_property.present?

    @current_property.leads.open
  end

  # Returns a list of leads that belong to the current property and user, and are currently in progress. The leads are sorted in ascending order by last name and then first name.
  #
  # @return [ActiveRecord::Relation] An ActiveRecord relation containing the leads that match the criteria.
  def my_leads
    @current_property.leads.where(user: @current_user).in_progress.
      order(last_name: :asc, first_name: :asc)
  end

  # Returns a sorted list of leads in the early pipeline for the current property.
  # Leads are sorted by priority in descending order, then by last name and first name in ascending order.
  # 
  # @return [ActiveRecord::Relation] a list of early pipeline leads for the current property, sorted as specified
  def all_leads
    @current_property.leads.early_pipeline.
      order(priority: :desc, last_name: :asc, first_name: :asc)
  end

  # Returns a sorted list of stale leads for the current property
  #
  # @return [ActiveRecord::Relation] all stale leads for the current property,
  # sorted by last name and first name in ascending order
  #
  # @raise [NoMethodError] if @current_property is nil
  def stale_leads
    @current_property.leads.stale.
      order(last_name: :asc, first_name: :asc)
  end

  def upcoming_appointments
    @current_user.scheduled_actions.appointments.having_schedule.pending.
      order('schedules.date ASC')
  end

  def my_tasks
    @current_user.scheduled_actions.pending
  end

  def all_tasks
    @current_user.team_tasks.pending
  end

  def stats
    start_date = Statistic.utc_month_start - 1.month
    @stats ||= UserStats.new(
      Statistic.tenacity_grade_for(@current_user, time_start: start_date),
      Statistic.lead_speed_grade_for(@current_user, interval: :month, time_start: start_date),
      Statistic.utc_month_start - 1.month
    )
  end

end
