class ScheduledActionsController < ApplicationController

  include ScheduledActionsHelper

  skip_before_action :verify_authenticity_token, only: [:conflict_check]
  before_action :authenticate_user!
  before_action :set_scheduled_action, only: [:show, :edit, :update, :destroy, :complete, :completion_form]
  before_action :set_lead, only: [:index, :show, :edit, :update, :destroy, :complete, :completion_form]
  before_action :set_user, only: [:index, :show, :edit, :update, :destroy, :complete, :completion_form]
  after_action :verify_authorized

  # GET /scheduled_actions
  # GET /scheduled_actions.json
  def index
    authorize ScheduledAction
    @all_tasks = (params[:all] || 'false') == 'true'
    @team_tasks = (params[:team] || 'false') == 'true'
    skope = nil
    @start_date = (Date.parse(params[:start_date]) rescue Date.current.beginning_of_month)

    if @lead
      # Lead id provide: scope Tasks to that Lead.
      unless LeadPolicy.new(current_user, @lead).show?
        raise Pundit::NotAuthorizedError, "not allowed to view this Lead's Tasks"
      end
      skope = @lead.scheduled_actions
    elsif @user
      # User id provided: scope Tasks to that User
      unless UserPolicy.new(current_user, @user).show?
        raise Pundit::NotAuthorizedError, "not allowed to view this User's Tasks"
      end
      skope = @user.scheduled_actions
    elsif @current_property
      if @team_tasks
        skope = policy_scope(ScheduledAction.for_property(@current_property).where(target_type: 'Lead'))
      else
        skope = current_user.scheduled_actions
      end
    else
      if @team_tasks
        # Show Lead Tasks for all users assigned to the current user's properties
        user_ids = PropertyUser.where(property_id: current_user.property_ids).pluck(:user_id).uniq
        skope = ScheduledAction.where(user_id: user_ids, target_type: 'Lead')
      else
        # Show only user Tasks
        skope = current_user.scheduled_actions
      end
    end

    unless @all_tasks
      skope = skope.includes(:lead_action).
        where(lead_actions: {name: LeadAction::SHOWING_ACTION_NAME})
    end

    skope = skope.where("scheduled_actions.created_at > ?", @start_date - 1.month)
    @scheduled_actions = skope.includes(:schedule).valid
  end


  # GET /scheduled_actions/1
  # GET /scheduled_actions/1.json
  def show
    authorize @scheduled_action
  end

  # GET /scheduled_actions/new
  def new
    @scheduled_action = ScheduledAction.new(new_scheduled_action_params)
    @scheduled_action.schedule = Schedule.new()
    authorize @scheduled_action
  end

  # GET /scheduled_actions/1/edit
  def edit
    authorize @scheduled_action
  end

  def completion_form
    authorize @scheduled_action
    set_completion_action_and_message
  end

  def complete
    authorize @scheduled_action
    set_completion_action_and_message
    if ( @completed = !@scheduled_action.pending? )
      @success = false
    else
      @success = trigger_scheduled_action_state_event(
        scheduled_action: @scheduled_action,
        event_name: @scheduled_action.completion_action,
        user: completion_user)
    end
    redirect_path = params[:return].present? ? request.referer : completion_form_scheduled_action_path(@scheduled_action)
    respond_to do |format|
      format.js
      format.html { redirect_to redirect_path }
    end
  end

  def conflict_check
    conflicts = false
    # Find the record or build
    id = params["scheduled_action"]["id"]
    @scheduled_action = ScheduledAction.where(id: id).first || ScheduledAction.new

    # Use the submitted Schedule attributes without saving
    @scheduled_action.schedule ||= Schedule.new
    @scheduled_action.schedule.attributes = conflict_check_params["schedule_attributes"]

    # Shuffle record ownership temporarily for policy authorization
    user = @scheduled_action.user || current_user
    @scheduled_action.user = current_user
    authorize @scheduled_action
    @scheduled_action.user = user
    conflicts = @scheduled_action.conflicting.any?

    respond_to do |format|
      format.json { render json: conflicts }
    end
  end

  # POST /scheduled_actions
  # POST /scheduled_actions.json
  def create
    @scheduled_action = ScheduledAction.new(scheduled_action_params)
    @scheduled_action.user = current_user
    @scheduled_action.target ||= @lead || current_user
    authorize @scheduled_action

    respond_to do |format|
      if @scheduled_action.save
        redirectpath = @scheduled_action.target == current_user ? scheduled_actions_path : url_for(@scheduled_action.target)
        format.html { redirect_to redirectpath, notice: 'Scheduled action was successfully created.' }
        format.json { render :show, status: :created, location: @scheduled_action }
      else
        format.html { render :new }
        format.json { render json: @scheduled_action.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scheduled_actions/1
  # PATCH/PUT /scheduled_actions/1.json
  def update
    authorize @scheduled_action
    respond_to do |format|
      if @scheduled_action.update(scheduled_action_params)
        redirectpath = @scheduled_action.target == current_user ? scheduled_actions_path : url_for(@scheduled_action.target)
        format.html { redirect_to redirectpath, notice: 'Scheduled action was successfully updated.' }
        format.json { render :show, status: :ok, location: @scheduled_action }
      else
        format.html { render :edit }
        format.json { render json: @scheduled_action.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scheduled_actions/1
  # DELETE /scheduled_actions/1.json
  def destroy
    authorize @scheduled_action
    redirectpath = @scheduled_action.target == current_user ? scheduled_actions_path : url_for(@scheduled_action.target)
    @scheduled_action.destroy
    respond_to do |format|
      format.html { redirect_to redirectpath, notice: 'Scheduled action was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def update_scheduled_action_form_on_action_change
    @scheduled_action = ScheduledAction.where(id: params[:scheduled_action_id]).first ||
      ScheduledAction.new(target_id: params[:target_id], target_type: params[:target_type])
    authorize @scheduled_action
    @lead_action = LeadAction.where(id: params[:lead_action_id]).first
    @scheduled_action.lead_action = @lead_action
  end

  def load_notification_template
    @scheduled_action = ScheduledAction.where(id: params[:scheduled_action_id]).first ||
      ScheduledAction.new(target_id: params[:target_id], target_type: params[:target_type])
    authorize @scheduled_action

    @message_template = MessageTemplate.find(params[:message_template_id])

    schedule_date = Time.zone.local(
      params[:schedule_date_1i].to_i, params[:schedule_date_2i].to_i, params[:schedule_date_3i].to_i,
      params[:schedule_time_4i].to_i, params[:schedule_time_5i].to_i, 0) + 1.hour
    schedule = Schedule.new(date: schedule_date.to_date, time: schedule_date.to_time)
    @scheduled_action.schedule = schedule

    @message = @scheduled_action.notification_message_content(@message_template)
  end

  private
    def set_scheduled_action
      @scheduled_action = ScheduledAction.find(params[:id])
    end

    def set_user
      user_id = params[:user_id]
      @user = user_id.present? ? User.active.find(user_id) : nil
    end

    def set_lead
      lead_id = params[:lead_id]
      @lead = lead_id.present? ? Lead.find(lead_id) : nil
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scheduled_action_params
      valid_params = policy(@scheduled_action || ScheduledAction).allowed_params
      params.require(:scheduled_action).permit(*valid_params)
    end

    def new_scheduled_action_params
      if params.fetch(:scheduled_action,nil).present?
        {
          target_id: params[:scheduled_action][:target_id],
          target_type: params[:scheduled_action][:target_type]
        }
      else
        {}
      end
    end

    def conflict_check_params
      filtered_params = scheduled_action_params
      filtered_params['schedule_attributes']['id'] = nil
      return filtered_params
    end

    def set_completion_action_and_message
      @scheduled_action ||= set_scheduled_action
      @scheduled_action.completion_action = params.fetch(:scheduled_action,{}).fetch(:completion_action, params[:event])
      @scheduled_action.completion_message = params.fetch(:scheduled_action,{}).fetch(:completion_message, params[:message])
      @scheduled_action.completion_retry_delay_value = params.fetch(:scheduled_action,{}).fetch(:completion_retry_delay_value, params[:retry_delay_value])
      @scheduled_action.completion_retry_delay_unit = params.fetch(:scheduled_action,{}).fetch(:completion_retry_delay_unit, params[:retry_delay_unit])
    end

    def completion_user
      user = ( policy(@scheduled_action).impersonate? && scheduled_action_params.fetch('impersonate', false) == "1" ) ?
        @scheduled_action.user :
        current_user
      return user
    end

end
