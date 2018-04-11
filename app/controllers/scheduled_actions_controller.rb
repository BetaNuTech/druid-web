class ScheduledActionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_scheduled_action, only: [:show, :edit, :update, :destroy, :complete, :completion_form]
  before_action :set_lead, only: [:show, :edit, :update, :destroy, :complete, :completion_form]
  before_action :set_user, only: [:show, :edit, :update, :destroy, :complete, :completion_form]
  after_action :verify_authorized

  # GET /scheduled_actions
  # GET /scheduled_actions.json
  def index
    authorize ScheduledAction
    if @lead
      @scheduled_actions = @lead.scheduled_actions
    elsif @user
      @scheduled_actions = @user.scheduled_actions
    else
      @scheduled_actions = current_user.scheduled_actions
    end
  end

  # GET /scheduled_actions/1
  # GET /scheduled_actions/1.json
  def show
  end

  # GET /scheduled_actions/new
  def new
    @scheduled_action = ScheduledAction.new
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
  end

  # POST /scheduled_actions
  # POST /scheduled_actions.json
  def create
    raise ActiveRecord::RecordNotFound
    @scheduled_action = ScheduledAction.new(scheduled_action_params)

    respond_to do |format|
      if @scheduled_action.save
        format.html { redirect_to @scheduled_action, notice: 'Scheduled action was successfully created.' }
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
    raise ActiveRecord::RecordNotFound
    respond_to do |format|
      if @scheduled_action.update(scheduled_action_params)
        format.html { redirect_to @scheduled_action, notice: 'Scheduled action was successfully updated.' }
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
    raise ActiveRecord::RecordNotFound
    @scheduled_action.destroy
    respond_to do |format|
      format.html { redirect_to scheduled_actions_url, notice: 'Scheduled action was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_scheduled_action
      @scheduled_action = ScheduledAction.find(params[:id])
    end

    def set_user
      user_id = params[:user_id]
      @user = user_id.present? ? User.find(user_id) : nil
    end

    def set_lead
      lead_id = params[:lead_id]
      @lead = lead_id.present? ? Lead.find(lead_id) : nil
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scheduled_action_params
      params.fetch(:scheduled_action, {})
    end

    def set_completion_action_and_message
      @scheduled_action ||= set_scheduled_action
      @scheduled_action.completion_action = params.fetch(:scheduled_action,{}).fetch(:completion_action, params[:event])
      @scheduled_action.completion_message = params.fetch(:scheduled_action,{}).fetch(:completion_message, nil)
    end

end
